FROM rundqvist/supervisor:1.1

LABEL maintainer="mattias.rundqvist@icloud.com"

WORKDIR /app

RUN apk add --update --no-cache openvpn libarchive-tools iptables

COPY root /

run wget --no-check-certificate -O /app/openvpn/provider/smartdns.sh https://github.com/stream2me/docker-openvpn/raw/master/root/app/openvpn/provider/smartdns.sh;

ENV VPN_PROVIDER='' \
    VPN_USERNAME='' \
	VPN_PASSWORD='' \
	VPN_COUNTRY='' \
	VPN_INCLUDED_REMOTES='' \
	VPN_EXCLUDED_REMOTES='' \
	VPN_REMOTES_FILTER_MODE='' \
	VPN_RANDOM_REMOTE='' \
	VPN_KILLSWITCH='true'
