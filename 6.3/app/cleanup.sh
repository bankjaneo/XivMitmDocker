#!/bin/bash
echo "Cleaning up..."

DEVICE_NAME=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
LOCAL_IP=$(ip addr show $DEVICE_NAME | grep "inet\b" | awk '{print $2}')

# Local Interface
if [ -z ${LOCAL+x} ] || [ "$LOCAL" = "true" ]; then
    for i in $(ip addr show $DEVICE_NAME | grep "inet\b" | awk '{print $2}'); do
        while IFS="" read -r SERVER_IP || [ -n "$SERVER_IP" ]; do
            iptables -t nat -D POSTROUTING -s $i -d $SERVER_IP -o $DEVICE_NAME -j MASQUERADE
        done < server-list.txt
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

            while IFS="" read -r SERVER_IP || [ -n "$SERVER_IP" ]; do
                iptables -t nat -D POSTROUTING -s $VPN_SUBNET -d $SERVER_IP -o $DEVICE_NAME -j MASQUERADE
            done < server-list.txt
            iptables -D FORWARD -i $DEVICE_NAME -o ${!var} -m state --state RELATED,ESTABLISHED -j ACCEPT
            iptables -D FORWARD -i ${!var} -o $DEVICE_NAME -j ACCEPT
        done
    fi
fi

# Clean up mitigate.py
rm /app/'<stdin>.cleanup.sh'
while IFS="" read -r SERVER_IP || [ -n "$SERVER_IP" ]; do
    iptables -t nat -S PREROUTING | grep $SERVER_IP | cut -d " " -f 2- | xargs -rL1 iptables -t nat -D
done < server-list.txt
