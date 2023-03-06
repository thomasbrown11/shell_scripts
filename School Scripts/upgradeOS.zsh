#!/bin/zsh

# Get username and password encoded in base64 format and stored as a variable in a script:
#TOKEN=$(printf username:password | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)

TOKEN=dGJyb3duOnNlY3JldFBhc3N3b3JkMTI=

#enter serial here, or send to device to have them run it (uncomment alt serialNumber definition)
#serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
#echo serialNumber $serialNumber
serialNumber=C02FR2EVQ6L5

#generate new token for jamf pro api calls... lasts 30 minutes
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
echo $BEARER

OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
#echo $OSversion

if [[ $OSversion < 12 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi

echo $api_token

deviceID=$(curl -s -H "Accept: text/xml" -H "Authorization: Bearer ${api_token}" https://mdirss.jamfcloud.com/JSSResource/computers/serialnumber/"$serialNumber" | xmllint --xpath '/computer/general/id/text()' -)

echo $deviceID

# Execute software update
#curl -X POST "https://mdirss.jamfcloud.com/api/v1/macos-managed-software-updates/send-updates" -H "accept: application/json" -H "Authorization: Bearer ${api_token}" -H "Content-Type: application/json" -d "{\"deviceIds\":[\"${deviceID}\"],\"maxDeferrals\":0,\"version\":\"13.0\",\"skipVersionVerification\":true,\"applyMajorUpdate\":true,\"updateAction\":\"DOWNLOAD_AND_INSTALL\",\"forceRestart\":true}"

URL=https://mdirss.jamfcloud.com
curl -X POST "$URL/api/v1/macos-managed-software-updates/send-updates" -H "accept: application/json" -H "Authorization: Bearer $api_token" -H "Content-Type: application/json" -d "{\"deviceIds\":[\"$deviceID\"],\"version\":\"13.0.1\",\"applyMajorUpdate\":true,\"updateAction\":\"DOWNLOAD_AND_INSTALL\",\"forceRestart\":true,\"priority\":\"HIGH\"}"
