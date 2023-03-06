#!/bin/zsh

jamfProUrl=https://mdirss.jamfcloud.com/JSSResource

jamfCreds=enrollment:mdirss


loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
mySerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
deviceID=$(curl -sku ${jamfCreds} -X GET -H "accept: application/xml" "${jamfProUrl}/computers/serialnumber/${mySerial}" | xmllint --xpath '//general/id/text()' -)

echo $loggedInUser
echo $mySerial
echo $deviceID
