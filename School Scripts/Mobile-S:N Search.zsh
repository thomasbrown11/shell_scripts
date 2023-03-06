#!/bin/zsh

#S/N List
mobileSerialList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/mobiledevices" -H "accept: application/xml" -fsu enrollment:mdirss | xmllint --xpath "mobile_devices/mobile_device/serial_number/text()" -)

#insert serial to check
#mySerial=C07CW1M3JG2X
mySerial=c07cw1M3JG2X
echo $mySerial
#edit for case-sensitive
newSerial=$(echo "$mySerial" | tr '[:lower:]' '[:upper:]')
echo $newSerial

#search serial list for serial
function contains ()
{
  [[ $mobileSerialList =~ (^|[[:space:]])$1($|[[:space:]]) ]] && myResult=0 || myResult=1
}
#call function to set myResult 0=serial found 1=serial not found
#contains $mySerial
contains $newSerial
echo $myResult

test
if [[ $myResult == 0 ]]
then
echo "hello"
else
echo "fail"
fi


