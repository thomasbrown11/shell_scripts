#!/bin/zsh

##Get Bearer Token for API Calls########
#Decrypt String for $TOKEN
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

#add U2FsdGVkX198+NoiNg9DEZ67T+Ua0LNJR5FM6ynfYXqxb0RplAOzEs/XgOqYa/sKQKws2O0C5QPkgekf0Y7VDw==
var1=U2FsdGVkX198+NoiNg9DEZ67T+Ua0LNJR5FM6ynfYXqxb0RplAOzEs/XgOqYa/sKQKws2O0C5QPkgekf0Y7VDw==
TOKEN=$(DecryptString $4 7cf8da22360f4311 09de0192edd3e4caaf3cb796) #change $var1 to $4 on deploy
echo "the token is $TOKEN"

##generate new bearer token for jamf pro api calls... lasts 30 minutes
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
echo $BEARER
#
OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
echo $OSversion
#
if [[ $OSversion < 13 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
echo "api token is $api_token"
########################################

##get serial and print
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
echo serialNumber $serialNumber

##MDIRSS jamf cloud
jamfProUrl=https://mdirss.jamfcloud.com

##get device id and print
deviceID=$(curl -k -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '//general/id/text()' -)
echo deviceID $deviceID

#Delete MDIRSS Spare User and remove uploaded Wallpaper image
user=$(dscl . ls \Users | grep "MDIRSS Spare User")
sudo dscl . delete /users/$user
sudo rm -rf /Users/MDIRSSspareuser
sudo rm -rf /usr/local/Desktop #add this to actual script

#Wipes Loan Status ext att
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value></value></extension_attribute></extension_attributes></computer>"

#Wipes username ext att
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value></value></extension_attribute></extension_attributes></computer>"

exit 0
