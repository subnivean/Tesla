#!/bin/bash

# Use `MAC` when static IP cannot be set 
# MAC="$(grep 'MAC='' secrets |cut -d'=' -f2)"
# Use `IP` when static IP set through DHCP
IP="$(grep 'IP=' secrets |cut -d'=' -f2)"

OUTFILE="output/tesla_gateway_meter_data.csv"
SLEEP=60  # seconds

while true;
do
   # Uncomment the following if IP is not static
   # (needs `sudo`)
   # IP="$(arp-scan -l |grep $MAC |cut -f1)"

   CMD1="curl -sk https://$IP/api/meters/aggregates"
   CMD2="curl -sk https://$IP/api/system_status/soe"
   CMD3="curl -sk https://$IP/api/system_status/grid_status"

   (echo "[" && $CMD1 && echo "," && $CMD2 && echo "," && $CMD3 && echo "]") | jq -r " \
    [ \
     .[0].load.last_communication_time, \
     .[0].site.instant_power, \
     .[0].load.instant_power, \
     .[0].solar.instant_power, \
     .[0].battery.instant_power, \
     .[1].percentage, \
     .[2].grid_status \
    ]
    | @csv" |./format.py >> $OUTFILE
    sleep $SLEEP
done
