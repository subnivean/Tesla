#!/bin/bash

MAC="$(grep MAC secrets |cut -d'=' -f2)"

OUTFILE="output/tesla_gateway_meter_data.csv"
SLEEP=180  # 3 * 60

while true;
do
   IP="$(arp-scan -l |grep $MAC |cut -f1)"
   # IP="192.168.1.5"  # Speeds up testing, once you know it.

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
    | @csv" >> $OUTFILE
    sleep $SLEEP
done
