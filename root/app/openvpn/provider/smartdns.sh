#!/bin/sh

while getopts ":e:c:" arg; do
    case $arg in
        e) exec=$OPTARG;;
        c) country=$OPTARG;;
    esac
done

log -v "Provider SmartDNSproxy $exec"

case $exec in

    #
    # Configure
    #
    configure)

    var VPN_PORT 1194

    ;;

    #
    # Resolve remote hostname
    #
    host)

        ip=$(tac /var/log/openvpn-$country.log | grep -m 1 'Peer Connection Initiated' | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

        log -v "Vpn ($country) connected to ip: $ip"

        while read -r remote
        do
            remoteIp=$(ping -q -c 1 $remote | head -n 1 | grep -oE '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

            log -v "Host $remote has ip $remoteIp"

            if [ "$ip" == "$remoteIp" ]
            then
                break
            fi
        done < /app/openvpn/$country-allowed.remotes

        if [ -z "$remote" ]
        then
            log -w "Failed to resolve remote hostname."
            exit 1;
        fi

        echo "$remote"

    ;;

    #
    # Setup
    #
    setup)

        countryName="$(var -k country $country)"
        log -d "Translating $country to $countryName"

        if [ -z "$(find /cache/openvpn/smartdns/ -name "$countryName*UDP*.ovpn")" ] ; then
            log -e "No config files found country $country. Ignoring. "
            exit 1;
        fi

        #
        # Copy one config file as template
        #
        find /cache/openvpn/smartdns/ -name "$countryName*UDP*.ovpn" -print | head -1 | xargs -I '{}' cp {} /app/openvpn/config-$country.ovpn

        #
        # Resolve remotes
        #
        find /cache/openvpn/smartdns/ -name "$countryName*UDP*.ovpn" -exec sed -n -e 's/^remote \(.*\) \(.*\)/\1/p' {} \; | sort > /app/openvpn/$country-allowed.remotes

    ;;

    #
    # Update
    #
    update)
    
        dateCurrent=$(date +%d)
        dateUpdated=$(cat /cache/openvpn/smartdns/date_updated 2>/dev/null)

        if [ "$dateCurrent" != "$dateUpdated" ]
        then
            log -i "Updating SmartDNSproxy configuration files."

            mkdir -p /cache/openvpn/smartdns/configs
            rm -f /cache/openvpn/smartdns/SmartDNSProxy-OpenVPN.zip

            wget -q https://network.glbls.net/openvpnconfig/SmartDNSProxy-OpenVPN.zip -P /cache/openvpn/smartdns/ 2>/dev/null
            
            if [ $? -eq 1 ]
            then
                log -w "Download failed. "
            else
                log -d "Extract configs."
                unzip -q -o /cache/openvpn/smartdns/SmartDNSProxy-OpenVPN.zip -d /cache/openvpn/smartdns/configs
                mv /cache/openvpn/smartdns/configs/UDP-1194/* /cache/openvpn/smartdns/
                rm -rf /cache/openvpn/smartdns/configs

                echo $dateCurrent > /cache/openvpn/smartdns/date_updated
            fi
        else
            log -d "Config recently updated. Skipping..."
        fi

    ;;
esac

exit 0;
