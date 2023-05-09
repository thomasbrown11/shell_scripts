#!/bin/zsh

# Get username and password encoded in base64 format and stored as a variable in a script:
#TOKEN=$(printf username:password | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)

TOKEN=REMOVED

#!/bin/bash

URL="https://mdirss.jamfcloud.com"
username=tbrown
password=REMOVED
encodedCredentials=$( printf "$username:$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )
echo $encodedCredentials
authToken=$( /usr/bin/curl "$URL/api/v1/auth/token" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )
token=$( /usr/bin/awk -F \" '/token/{ print $4 }' <<< "$authToken" | /usr/bin/xargs )
ID=2417

echo $token
#echo $authToken

#curl -X POST "$URL/api/v1/macos-managed-software-updates/send-updates" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "{\"deviceIds\":[\"$ID\"],\"skipVersionVerification\":true,\"applyMajorUpdate\":true,\"updateAction\":\"DOWNLOAD_AND_INSTALL\",\"forceRestart\":true,\"priority\":\"HIGH\"}"
