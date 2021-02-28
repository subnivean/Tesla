#!/bin/bash

# Use `MAC` when static IP cannot be set
# MAC="$(grep 'MAC='' secrets |cut -d'=' -f2)"
# Use `IP` when static IP set through DHCP
IP="$(grep 'IP=' secrets |cut -d'=' -f2)"
TESLA='/home/pi/.tesla'
OUTFILE="output/tesla_gateway_meter_data.csv"
SLEEP=60  # seconds

LOGINCMD="curl -s -k -i \
          -c $TESLA/cookie.txt \
          -X POST \
          -H ""Content-Type: application/json"" \
          -d @$TESLA/creds.json \
          https://$IP/api/login/Basic"

echo "Logging in..."
$LOGINCMD >/dev/null

while true;
do
    TIMESTAMP="$(date -I'seconds')"
    # Note explicit conversion of numbers to base 10; otherwise
    # they are interpreted as octal numbers, causing errors
    # with '08' and '09'.
    # Found fix at: https://stackoverflow.com/questions/24777597
    MIN=$((10#$(date "+%M")))

    # Get a new token every hour (or maybe 2, if we don't land
    # on zero because of processing time)
    if [[ $MIN -eq 4 ]]
    then
        echo "$TIMESTAMP: Getting new gateway token..."
        $LOGINCMD >/dev/null
    fi

    # Uncomment the following if IP is not static
    # (needs `sudo`)
    # IP="$(arp-scan -l |grep $MAC |cut -f1)"

    CMD1="curl -sk -b $TESLA/cookie.txt https://$IP/api/meters/aggregates"
    CMD2="curl -sk -b $TESLA/cookie.txt https://$IP/api/system_status/soe"
    CMD3="curl -sk -b $TESLA/cookie.txt https://$IP/api/system_status/grid_status"

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

    # Add last record to database
    echo "$(tail -n1 output/tesla_gateway_meter_data.csv)" | ./add_api_rec_to_database.py

    sleep $SLEEP
done
