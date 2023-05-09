#.!/bin/zsh

#credentials=tbrown:Knothole11

#S/N List for all MDIRSS devices
mobileSerialList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/mobiledevices" -H "accept: application/xml" -fsu enrollment:REDACTED | xmllint --xpath "mobile_devices/mobile_device/serial_number/text()" -)

echo $mobileSerialList

while [[ $accountResult != 0 ]]
do

#get jamf username
username=$(osascript << EOF
text returned of (display dialog "Please enter JAMF username" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
# Check status of osascript, exit script if "Cancel" selected
# necessary to break loop
if [ "$?" != "0" ] ; then
   echo "User aborted. Exiting..."
   exit 1
fi
echo $username

#get jamf password
pw=$(osascript << EOF
text returned of (display dialog "Please enter JAMF password" default answer "" with hidden answer buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
# Check status of osascript, exit script if "Cancel" selected
# necessary to break loop
if [ "$?" != "0" ] ; then
   echo "User aborted. Exiting..."
   exit 1
fi
echo $pw

#combine username:password
credentials=${username}:${pw}
echo $credentials

#check creds
###############

#get all MDIRSS jamf users
jamfAccountList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -fsu $credentials | xmllint --xpath "accounts/users/user/name/text()" -)
echo $jamfAccountList

#function to check if jamfAccountList contains entered username. Returen 0 if yes, 1 if no
function accountContains ()
{
  [[ $jamfAccountList =~ (^|[[:space:]])$1($|[[:space:]]) ]] && accountResult=0 || accountResult=1
}
#call function to set myResult 0=serial found 1=serial not found
accountContains $username
echo $accountResult

if [[ $accountResult != 0 ]]
then
osascript << EOF
display dialog "User name or password not found. Please try again." buttons {"OK"} default button 1
EOF
#exit 1
fi

done

#prompt user for S/N, set as serialNumber variable.. loop if invalid result
while [[ $myResult != 0 ]]
do
#if serial not found in mobileSerialList
if [[ $myResult == 1 ]]
then
serialNumber=$(osascript << EOF
text returned of (display dialog "${serialNumber} not found. Please enter valid serial number" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
#if first loop (myResult not set yet)
else
serialNumber=$(osascript << EOF
text returned of (display dialog "Please enter serial number" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
fi

# Check status of osascript, exit script if "Cancel" selected
# necessary to break loop
if [ "$?" != "0" ] ; then
   echo "User aborted. Exiting..."
   exit 1
fi

#change to uppercase if needed
serialNumber=$(echo "$serialNumber" | tr '[:lower:]' '[:upper:]')

#search s/n list for device serial
function contains ()
{
  [[ $mobileSerialList =~ (^|[[:space:]])$1($|[[:space:]]) ]] && myResult=0 || myResult=1
}
#call function to set myResult 0=serial found 1=serial not found
contains $serialNumber
echo $myResult
done


osascript << EOF
display dialog "Found records for $serialNumber" buttons {"OK"} default button 1
EOF

#prompt dropdown to select user type
loanOption=$(osascript << EOF
set loanOptions to {"Ready to Loan", "Staff", "Student", "Substitute Teacher"}
set selectedLoanOption to choose from list loanOptions with prompt "Select User Type:" default items "ready to loan"
selectedLoanOption
EOF
)
echo $loanOption

#if Ready to Loan selected then skip, if not then collect user name info
if [[ $loanOption != "Ready to Loan" ]]
then
##prompt for name
deviceUser=$(osascript << EOF
text returned of (display dialog "Please enter borrower first and last name" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
echo $deviceUser
fi

osascript << EOF
display dialog "Changing $serialNumber user status to $loanOption" buttons {"OK"} default button 1
EOF

#GET call- return loan status
#curl -sku $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "accept: text/xml" | xmllint --xpath "mobile_device/extension_attributes/extension_attribute/value/text()" -

#Changes loan status to chosen selection from loanOption
curl -fu $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>1</id><value>$loanOption</value></extension_attribute></extension_attributes></mobile_device>"
#save curl exit code for testing
res=$?
echo $res
#if curl fails returns exit code 22.. display error and exit program.
if [[ $res != 0 ]]
then
osascript << EOF
display dialog "Request failed with exit code: ${res}. Please check JAMF credentials and try again." buttons {"OK"} default button 1
EOF
exit 1
fi

#continue if success..
#update iPad Loaned To status with current details
#If Ready to Loan selected then leave empty/delete.. else set to user's name.
if [[ $loanOption != "Ready to Loan" ]]
then

curl -fu $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>2</id><value>$deviceUser</value></extension_attribute></extension_attributes></mobile_device>"
#provide success message to user
osascript << EOF
display dialog "$serialNumber successfully borrowed by $deviceUser and moved to the $loanOption smart group" buttons {"OK"} default button 1
EOF
else
curl -fu $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>2</id><value></value></extension_attribute></extension_attributes></mobile_device>"
#provide success message to user
osascript << EOF
display dialog "$serialNumber successfully returned to spares" buttons {"OK"} default button 1
EOF
fi

#if API calls succeed provide success message to user
#osascript << EOF
#display dialog "$serialNumber successfully borrowed by $deviceUser and moved to the $loanOption smart group" buttons {"OK"} default button 1
#EOF

#test machine
#JC9C2NVDQV
#DMPPX9LQFK11

#add user to the device-> configure userName following same procedure as for laptops
#remove user name from device when changed



