#!/bin/zsh

##MDIRSS jamf cloud
jamfProUrl=https://mdirss.jamfcloud.com

##get serial and print
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
#echo serialNumber $serialNumber

#basic
TOKEN=dGJyb3duOnNlY3JldFBhc3N3b3JkMTI=

#generate new token for jamf pro api calls... lasts 30 minutes
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
#echo $BEARER

#get OSversion on user computer
OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
#echo $OSversion

#parse BEARER JSON based on current version to set api_token to usable auth token
if [[ $OSversion < 13 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
#echo $api_token

##get device id and print
deviceID=$(curl -sk -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '//general/id/text()' -)
#echo deviceID $deviceID

#Changes loan status to chosen selection from loanOption
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value>Ready to Loan</value></extension_attribute></extension_attributes></computer>"

#Changes userName to selection from $userName
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value></value></extension_attribute></extension_attributes></computer>"

echo "Script Complete"

#error handle to throw error if failed? Might not be worth it.

#sometimes users just shut their computer and don't log out... logging out is the ideal trigger, but can you auto log them out after x amount of time?

#how do you target logout?
#NOT TESTED
#on quit
#        do shell script "PUT YOUR STOP SCRIPT PATH HERE"
#        continue quit
#    end quit
