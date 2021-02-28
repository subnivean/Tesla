#!/usr/bin/env python3
"""Add the latest data record captured through
the Tesla API to the sqlite database. Piped to
from inside `get_tesla_gateway_meter_data.sh`.
"""
import datetime
from pathlib import Path
import pytz
import sqlite3
import sys

import pandas as pd

# Data record is being piped in from a bash script
# apirec = "2021-02-28T09:56:11-05:00",  -642.81,  1027.89,  1668.86,    10.00,    99.04, "SystemGridConnected"
#apirec = " ".join(sys.argv[1:])
apirec = sys.stdin.read()

COLUMNS = "DateTime,Grid_kW,Home_kW,Solar_kW,Powerwall_kW,BattLevel,GridStatus".split(',')

fields = [f.strip().strip('"') for f in apirec.split(",")]
fields[1:-1] = map(float, fields[1:-1])
df = pd.DataFrame([fields], columns=COLUMNS)
# Convert numbers to kilowatts
df[['Grid_kW', 'Home_kW', 'Solar_kW', 'Powerwall_kW']] /= 1000

df['DateTime'].map(datetime.datetime.fromisoformat)
df = df.set_index(['DateTime'])

# Open the database and read the last timestamp.
con = sqlite3.connect("energy.sqlite")
cursor = con.cursor()
cursor.execute("SELECT DateTime FROM energy_data ORDER BY DateTime DESC LIMIT 1")
lastdate = pd.to_datetime(cursor.fetchone()[0], utc=True).tz_convert('US/Eastern')

ts = datetime.datetime.fromisoformat(df.index[0])
ts.replace(tzinfo=pytz.timezone('US/Eastern'))

# Get time delta
td = ts - lastdate.to_pydatetime()

# Add calculated fields
df['delta_hours'] = td.total_seconds() / 3600
df['Home_kWh'] = df['Home_kW'] * df['delta_hours']
df['Solar_kWh'] = df['Solar_kW'] * df['delta_hours']
df['Powerwall_kWh'] = df['Powerwall_kW'] * df['delta_hours']
df['Grid_kWh'] = df['Grid_kW'] * df['delta_hours']

# Add to the database
df.to_sql('energy_data', con, if_exists='append')
