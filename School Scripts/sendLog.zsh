#!/bin/zsh

#variables
jamfProUrl=https://mdirss.jamfcloud.com/JSSResource
jamfCreds=enrollment:mdirss
mySerial=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
deviceID=$(curl -sku ${jamfCreds} -X GET -H "accept: application/xml" "${jamfProUrl}/computers/serialnumber/${mySerial}" | xmllint --xpath '//general/id/text()' -)

#api POST to attachments in computer section- upload system.log

curl -sku $jamfCreds $jamfProUrl/fileuploads/computers/id/$deviceID -F name=@/var/log/system.log -X POST


