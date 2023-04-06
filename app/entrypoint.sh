#!/bin/bash

SCRIPT_URL="https://raw.githubusercontent.com/Soreepeong/XivMitmLatencyMitigator/main/mitigate.py"
DEVICE_NAME=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

> definitions.json
> server-list.txt

if [ -z ${MITIGATOR+x} ] || [ "$MITIGATOR" = "true" ]; then
    # Check connection to XivMitmLatencyMitigator script.
    while ! curl --connect-timeout 5 -sfL $SCRIPT_URL > /dev/null; do
        echo "Cannot download script, retry in 5 seconds."
        sleep 5
    done

    # Create definitions.json.
    if [ -z ${DEFINITIONS_URL+x} ]; then
        definition_urls=`curl -s https://api.github.com/repos/Soreepeong/XivAlexander/contents/StaticData/OpcodeDefinition | jq -r '.[] | select(.name|test(".json$")) | .download_url '`
        for url in $definition_urls; do
            curl -O -s $url
        done
        echo -n "[" >> definitions.json
        for file in game.*.json; do
            cat $file | jq --arg file "$file" '. += {"Name": $file}' | tr -d '[:space:]' >> definitions.json
            echo -n "," >> definitions.json
        done
        echo -n "]" >> definitions.json
        sed -i 's/},]/}]/' definitions.json
        jq . definitions.json > definitions.tmp
        rm *.json
        mv definitions.tmp definitions.json

        if [ ! -s definitions.json ]; then
            echo "Could not create definitions.json, maybe hitting Github API limit. Wait about an hour before try again."
            exit
        fi
    else
        curl -s $DEFINITIONS_URL -o definitions.json
        jq . definitions.json > definitions.tmp
        rm *.json
        mv definitions.tmp definitions.json

        if [ ! -s definitions.json ]; then
            echo "Could not download definitions.json. Please check your link and try again."
            exit
        fi
    fi
fi

# Create server IP list.
cat definitions.json | jq -r '.[] | .Server_IpRange' | sed -e 's/,/\n/g' >> server-list.txt
if [ ! -s server-list.txt ]; then
    cp backup-server-list.txt server-list.txt
fi

# Clean up old iptables rules.
/app/cleanup.sh

# Check if iptables-legacy is set.
if [ "$LEGACY" = "true" ]; then
    update-alternatives --set iptables /usr/sbin/iptables-legacy
fi

# Local Interface
if [ -z ${LOCAL+x} ] || [ "$LOCAL" = "true" ]; then
    for i in $(ip addr show $DEVICE_NAME | grep "inet\b" | awk '{print $2}'); do
        iptables -t nat -A POSTROUTING -s $i -o $DEVICE_NAME -j MASQUERADE
    done
else
    if [ "$LOCAL" = "false" ]; then
        echo "Not using in LAN."
    fi
fi

# VPN Interface
if [ -z ${VPN+x} ]; then
    echo "No VPN set."
else
    if [ "$VPN" = "true" ]; then
        for var in "${!VPN_INTERFACE_@}"; do
            VPN_SUBNET=$(ip addr show ${!var} | grep "inet\b" | awk '{print $2}')

            # Create iptables fules for VPN routing.
            while IFS="" read -r SERVER_IP || [ -n "$SERVER_IP" ]; do
                iptables -t nat -A POSTROUTING -s $VPN_SUBNET -d $SERVER_IP -o $DEVICE_NAME -j MASQUERADE
            done < server-list.txt
            iptables -A FORWARD -i $DEVICE_NAME -o ${!var} -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -A FORWARD -i ${!var} -o $DEVICE_NAME -j ACCEPT
        done
    fi
fi

# Running mitigate.py
if [ -z ${MITIGATOR+x} ] || [ "$MITIGATOR" = "true" ]; then
    curl -s $SCRIPT_URL -o mitigate.py

    # Convert iptables to iptables-legacy if set.
    if [ "$LEGACY" = "true" ]; then
        sed -i "s/iptables -t/iptables-legacy -t/" mitigate.py
    fi
    exec python3 mitigate.py -m &
else
    if [ "$MITIGATOR" = "false" ]; then
        echo "XivMitmLatencyMitigator is disabled."
    fi
fi

# SIGTERM
cleanup() {
    /app/cleanup.sh
    exit
}

trap cleanup INT TERM

while :; do
    sleep 1s
done
