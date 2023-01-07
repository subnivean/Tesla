import sqlite3
import pandas as pd
import shutil

OLDDBFILE = "energy.sqlite.old"
NEWDBFILE = OLDDBFILE.replace('.old', '')

shutil.copy(OLDDBFILE, NEWDBFILE)

conn = sqlite3.connect(OLDDBFILE)

qry = "SELECT datetime(DateTime, 'utc') as DateTime2, * FROM energy_data"
df = pd.read_sql(qry, conn, parse_dates={"DateTime2": {"utc": True}})
conn.close()

tdf = df.drop(['Grid_kWh', 'Orwell_kWh', 'Solar_kWh', 'Home_kWh', 'Powerwall_kWh', 'delta_hours', 'DateTime'], axis=1)
tdf = tdf.rename({"DateTime2": "DateTime"}, axis=1)

cdf = pd.read_csv('output/tesla_gateway_meter_data.csv')
cdf['DateTime'] = pd.to_datetime(cdf['DateTime'], utc=True)
cdf['GridStatus'] = cdf['GridStatus'].str.strip().str.replace('"', '')
cdf['Orwell_kW'] = 0.0
cdf[['Grid_kW', 'Home_kW', 'Solar_kW', 'Powerwall_kW', 'BattCapacitykWh']] /= 1000.

mdf = tdf.merge(cdf, on=['DateTime'], how='right', suffixes=["_x", None], indicator=True)

cmdf = mdf[mdf['_merge'] == 'right_only'][cdf.columns]
findf = tdf.append(cmdf, ignore_index=True)
findf = findf.sort_values(by=['DateTime'], ignore_index=True)

findf['delta_hours'] = findf['DateTime'].dropna().diff() / pd.to_timedelta(1, unit='H')
findf['Home_kWh'] = findf['Home_kW'] * findf['delta_hours']
findf['Solar_kWh'] = findf['Solar_kW'] * findf['delta_hours']
findf['Powerwall_kWh'] = findf['Powerwall_kW'] * findf['delta_hours']
findf['Grid_kWh'] = findf['Grid_kW'] * findf['delta_hours']
findf['Orwell_kWh'] = findf['Orwell_kW'] * findf['delta_hours']
findf = findf.set_index(['DateTime'])

conn2 = sqlite3.connect(NEWDBFILE)
cur = conn2.cursor()
cur.execute("DELETE FROM energy_data")
conn2.commit()
findf.to_sql('energy_data', conn2, if_exists='append')
conn2.close()

