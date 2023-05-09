#.!/bin/zsh

#prompt creds
credentials=$(osascript << EOF
text returned of (display dialog "Please enter credentials: username:password" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
echo $credentials

#prompt user for S/N, set as serialNumber variable
serialNumber=$(osascript << EOF
text returned of (display dialog "Please enter serial number" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)

echo "changing loan status (ext att) of iPad with S/N of $serialNumber"

#prompt dropdown to select user type
loanOption=$(osascript << EOF
set loanOptions to {"Ready to Loan", "Staff", "Student", "Substitute Teacher"}
set selectedLoanOption to choose from list loanOptions with prompt "Select User Type:" default items "ready to loan"
selectedLoanOption
EOF
)
echo $loanOption

#GET call- return loan status
#curl -sku $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "accept: text/xml" | xmllint --xpath "mobile_device/extension_attributes/extension_attribute/value/text()" -

#Changes loan status to chosen selection from loanOption
curl -u $credentials https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/$serialNumber -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>1</id><value>$loanOption</value></extension_attribute></extension_attributes></mobile_device>"

#give user status update
osascript << EOF
display dialog "$serialNumber moved to the $loanOption group" buttons {"OK"} default button 1
EOF
