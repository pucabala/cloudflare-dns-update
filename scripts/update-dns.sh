#!/usr/bin/env bash

## Author: Hyecheol (Jerry) Jang
## Shell Script to check current public (dynamic) IP address of server,
## and update it to the Cloudflare DNS record after comparing IP address registered to Cloudflare

## get current public IP address
currentIP=$(curl -s checkip.amazonaws.com)
if [[ $? == 0 ]] && [[ ${currentIP} ]]; then  ## when curl command run without error
    ## Making substring, only retrieving IP address of this server
    currentIP=$(echo $currentIP | cut -d'"' -f 2)
    echo "Current public IP address is "$currentIP
else  ## error happens
    echo "Check your internet connection" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
    exit
fi

## Read configuration
CONFIG_PATH="/opt/cloudflare-dns-update/config/config.json"
apiKey=$(jq -r '.api' $CONFIG_PATH)
name=($(jq -r '."update-target"[].name' $CONFIG_PATH))
id=($(jq -r '."update-target"[].id' $CONFIG_PATH))
zoneid=($(jq -r '."update-target"[].zone_id' $CONFIG_PATH))
unset CONFIG_PATH

# Error Checks
if [[ ${#name[@]} != ${#id[@]} ]]; then
  echo "Config file Disrupted!!" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
  echo "Please re-generate config.json file (run configure.sh)" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
  exit
fi

index=0
while [[ $index -lt ${#id[@]} ]]; do # For all update targets in config file
  # Retrieve current DNS status
  dnsStatusAPICall=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneid[index]}/dns_records/${id[index]}" \
                             -H "Authorization: Bearer $apiKey" \
                             -H "Content-Type:application/json" | jq .)
  
  # Check for status
  if [[ $(echo $dnsStatusAPICall | jq .success) != true ]] || [[ $(echo $dnsStatusAPICall | jq -r .result.name) != ${name[index]} ]]; then
    echo "Error Occurred While Accessing Current DNS Status" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
    echo "May Be Caused by outdated config file. Please re-generate config.json file (run configure.sh)" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
    exit
  fi

  # compare recordIP with currentIP
  if [[ $(echo $dnsStatusAPICall | jq -r .result.content) == $currentIP ]]; then
    echo "${name[index]}: no need to update" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
  else # Need to update
    proxied=$(echo $dnsStatusAPICall | jq -r .result.proxied)
    ttl=$(echo $dnsStatusAPICall | jq -r .result.ttl)
    # JSON requestBody
    data="{\"type\":\"A\",\"name\":\"${name[index]}\",\"content\":\"$currentIP\",\"ttl\":$ttl,\"proxied\":$proxied}"
    unset proxied
    unset ttl
    
    # Update the entry
    updateResult=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneid[index]}/dns_records/${id[index]}" \
                           -H "Authorization: Bearer $apiKey" \
                           -H "Content-Type: application/json" \
                           --data $data | jq .)
    unset data

    # Check for result
    if [[ $(echo $updateResult | jq -r .success) != true ]] || [[ $(echo $updateResult | jq -r .result.content) != $currentIP ]]; then
      echo "Error While updating ${name[index]}" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
    else
      echo "${name[index]}: successfully updated to $currentIP" | tee -a /opt/cloudflare-dns-update/logs/update-dns.log
    fi
    unset updateResult
  fi
  
  index=$[$index+1]
done
unset index
unset apiKey
unset name
unset id
unset zoneid
unset currentIP
