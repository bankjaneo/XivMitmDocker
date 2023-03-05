#!/bin/bash

SCRIPT_URL="https://raw.githubusercontent.com/Soreepeong/XivMitmLatencyMitigator/main/mitigate.py"
DEVICE_NAME=$(ip route get 8.8.8.8 | awk -- '{printf $5}')

# Check Internet connection function
check_internet () {
    while ! curl --connect-timeout 5 -sfL $SCRIPT_URL > /dev/null; do
        echo "No Internet connection. Retry in 5 seconds."
        sleep 5
    done
}

# Create server IP list.
check_internet
definition_urls=`curl -s https://api.github.com/repos/Soreepeong/XivAlexander/contents/StaticData/OpcodeDefinition | jq -r '.[] | select(.name|test(".json$")) | .download_url '`
> server-list.txt
for url in $definition_urls; do
    curl -s $url | jq -r '.Server_IpRange' | sed -e 's/, /\n/g' >> server-list.txt
done
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
    curl $SCRIPT_URL -o mitigate.py

    # Convert iptables to iptables-legacy if set.
    if [ "$LEGACY" = "true" ]; then
        sed -i "s/iptables -t/iptables-legacy -t/" mitigate.py
    fi
    exec python3 mitigate.py -u -m &
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
