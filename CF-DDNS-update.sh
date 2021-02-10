#!/usr/bin/env bash
set -euo pipefail

#set log format
log_print () {
  echo "$(date "+[%Y/%m/%d, %H:%M:%S] ")$1"
}


#get options
while getopts ":c:s:r:z:t:T:p:f:" opt; do
  case $opt in
  	c)	CONFIG_FILE=$OPTARG
		;;
    s)	CFTOKEN=$OPTARG
	  	;;
    r)	RECORD_NAME=$OPTARG
    	;;
    z)	ZONE_NAME=$OPTARG
		;;
    t)	RECORD_TYPE=$OPTARG
		;;
    T)	RECORD_TTL=$OPTARG
		;;
	p)	RECORD_PROXIED=$OPTARG
		;;
	f)	FORCE=$OPTARG
		;;
	\?) log_print "Invalid option: -$OPTARG"
    	exit 1
    	;;
  esac
done

#source the config file if provided
if [ ! -z ${CONFIG_FILE+x} ] && [ -f $CONFIG_FILE ]; then
	source $CONFIG_FILE
elif [ ! -z ${CONFIG_FILE+x} ]; then
	log_print "Error with the config file"
	log_print "check if the path is correct"
	exit 1
fi

#set default values
if [ -z ${RECORD_TYPE+x} ] || [ "$RECORD_TYPE" = "" ]; then
	RECORD_TYPE=A
fi
if [ -z ${RECORD_TTL+x} ] || [ "$RECORD_TTL" = "" ]; then
	RECORD_TTL=120
fi
if [ -z ${RECORD_PROXIED+x} ] || [ "$RECORD_PROXIED" = "" ]; then
	RECORD_PROXIED="false"
fi
if [ -z ${FORCE+x} ] || [ "$FORCE" = "" ]; then
	FORCE="false"
fi

#check the required parameters
if [ -z ${CFTOKEN+x} ] || [ "$CFTOKEN" = "" ]; then
	log_print "Missing API Token!"
	log_print "Save it in config file or use the -s flag"
	exit 1
fi
if [ -z ${RECORD_NAME+x} ] || [ "$RECORD_NAME" = "" ]; then
	log_print "Missing record name!"
	log_print "Save it in config file or use the -r flag"
	exit 1
fi
if [ -z ${ZONE_NAME+x} ] || [ "$ZONE_NAME" = "" ]; then
	log_print "Missing zone name!"
	log_print "Save it in config file or use the -z flag"
	exit 1
fi

#check if the record name includes the zone name
if [ "$RECORD_NAME" != "$ZONE_NAME" ] && [ ! -z ${RECORD_NAME##*.$ZONE_NAME} ]; then
	log_print "The record name must be a full domain name"
	log_print "(eg. \"test.test.com\", not only \"test\")"
	exit 1
fi

#obtain the new IP
if [ "$RECORD_TYPE" = "A" ]; then
	PUBLIC_IP=$(curl -s http://ipv4.icanhazip.com)
else
	PUBLIC_IP=$(curl -s http://ipv6.icanhazip.com)
fi

#obtain last IP
if [ -f $HOME/.cf_ddns_lastIP ]; then
	LAST_IP=$(cat $HOME/.cf_ddns_lastIP)
else
	LAST_IP=""
fi

#check if IP has changed
if [ "$FORCE" == "false" ] && [ "$PUBLIC_IP" = "$LAST_IP" ]; then
	log_print "No update needed"
	exit 0
fi

#obtain zone id
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
     -H "Authorization: Bearer $CFTOKEN" \
     -H "Content-Type: application/json")
SUCCESS=$(echo $RESPONSE | jq .success)
if [ "$SUCCESS" = "false" ]; then
	log_print "Error getting zone id"
	log_print "Response: $RESPONSE"
	exit 2
fi
ZONE_ID=$(echo $RESPONSE | jq -r '.result[0].id')

#obtain record id
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
     -H "Authorization: Bearer $CFTOKEN" \
     -H "Content-Type: application/json")
SUCCESS=$(echo $RESPONSE | jq .success)
if [ "$SUCCESS" = "false" ]; then
	log_print "Error getting record id"
	log_print "Response: $RESPONSE"
	exit 2
fi
RECORD_ID=$(echo $RESPONSE | jq -r '.result[0].id')

#updating IP
if [ "$RECORD_PROXIED" = "true" ]; then
	SUCCESS=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
	     -H "Authorization: Bearer $CFTOKEN" \
	     -H "Content-Type: application/json" \
	     --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$PUBLIC_IP\",\"proxied\":true}" | jq .success)
else
	SUCCESS=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
	     -H "Authorization: Bearer $CFTOKEN" \
	     -H "Content-Type: application/json" \
	     --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$PUBLIC_IP\",\"ttl\":$RECORD_TTL,\"proxied\":false}" | jq .success)
fi
if [ "$SUCCESS" = "false" ]; then
	log_print "Error updating ip"
	log_print "Response: $RESPONSE"
	exit 2
else
	log_print "IP updated successfully"
fi

#save current IP
if [ "$FORCE" == "false" ]; then
	echo $PUBLIC_IP > $HOME/.cf_ddns_lastIP
fi

