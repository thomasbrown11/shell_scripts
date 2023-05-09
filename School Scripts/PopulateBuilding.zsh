#!/bin/zsh

##MDIRSS jamf cloud
jamfProUrl=https://mdirss.jamfcloud.com
#
##get serial
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
echo $serialNumber

##GENERATE BEARER TOKEN FOR API CALLS##################

function DecryptString() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

##removed decryption string
TOKEN=$(DecryptString ?? 7cf8da22360f4311 09de0192edd3e4caaf3cb796)
echo $TOKEN

#generate new token for jamf pro api calls... lasts 30 minutes
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
echo $BEARER

#get OSversion on user computer
OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
echo $OSversion

#parse BEARER JSON based on current version to set api_token to usable auth token
if [[ $OSversion < 11 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
echo $api_token

##########################################################

##get device id and print
deviceID=$(curl -k -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '//general/id/text()' -)
echo "your deviceID is $deviceID"

##get device site
deviceSite=$(curl -k -H "Authorization: Bearer $api_token" -H "accept: application/xml" $jamfProUrl/JSSResource/computers/id/$deviceID | xmllint --xpath '//general/site/name/text()' -)
echo "your device site is $deviceSite"

case $deviceSite in
    "Central Office")
        buildingID=8; buildingName="Central Office"
        ;;
    "Conners Emerson")
        buildingID=6; buildingName="Conners Emerson School"
        ;;
    "Cranberry Schools")
        buildingID=9; buildingName="Cranberry"
        ;;
    "Frenchboro")
        buildingID=3; buildingName="Frenchboro"
        ;;
    "Mount Desert Elementary")
        buildingID=7; buildingName="MDES"
        ;;
    "Mount Desert Island High School")
        buildingID=4; buildingName="MDIHS"
        ;;
    "Pemetic")
        buildingID=1; buildingName="Pemetic Elementary"
        ;;
    "Swan")
        buildingID=10; buildingName="Swan"
        ;;
    "Tremont")
        buildingID=2; buildingName="Tremont"
        ;;
    "Trenton")
        buildingID=5; buildingName="Trenton"
    
esac
        
echo $buildingID; echo $buildingName

##Changes building to based on site
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><location><building>$buildingName</building></location></computer>"

#curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/2448 -H "content-type: text/xml" -X PUT -d "<computer><location><building>$buildingName</building></location></computer>"

#sudo jamf recon -building $buildingName #this works but triggers recon as well

exit 0
