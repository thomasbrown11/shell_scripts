#!/bin/zsh

##MDIRSS jamf cloud
jamfProUrl=https://mdirss.jamfcloud.com
#
##get serial and print
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
echo serialNumber $serialNumber
#

# Get username and password encoded in base64 format and stored as a variable in a script:
#TOKEN=$(printf username:password | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)
TOKEN=dGJyb3duOnNlY3JldFBhc3N3b3JkMTI=

#generate new token for jamf pro api calls... lasts 30 minutes
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
echo $BEARER

#get OSversion on user computer
OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
echo $OSversion

#parse BEARER JSON based on current version to set api_token to usable auth token
if [[ $OSversion < 13 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
echo $api_token

#-H "Authorization: Bearer $api_token" replaces all -u ${credentials}

##gameplan: get generic user so prompt creds can be deleted and changed to credentials=generic:password whatever
#
#credentials=$(osascript << EOF
#text returned of (display dialog "Please enter credentials: username:password" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
#EOF
#)
#echo credentials $credentials
#
##get device id and print
deviceID=$(curl -sk -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '//general/id/text()' -)
echo deviceID $deviceID
#
##create ext. attribute for computer instead of iPad and configure smart groups accordingly DONE
#
##prompt dropdown to select user type
loanOption=$(osascript << EOF
set loanOptions to {"Ready to Loan", "Staff", "Student", "Substitute Teacher"}
set selectedLoanOption to choose from list loanOptions with prompt "Select User Type:" default items "ready to loan"
selectedLoanOption
EOF
)
echo loanOption $loanOption

#if Ready to Loan selected then skip, if not then collect user name info
if [[ $loanOption != "Ready to Loan" ]]
then
##prompt for name
userName=$(osascript << EOF
text returned of (display dialog "Please enter borrower first and last name" default answer "" buttons {"Continue"} default button "Continue")
EOF
)
echo $userName
fi

osascript << EOF
display dialog "Changing $serialNumber user status to $loanOption" buttons {"OK"} default button 1
EOF

#
##prompt for name
#userName=$(osascript << EOF
#text returned of (display dialog "Please enter your first and last name" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
#EOF
#)
#echo userName $userName
#
##test with this get call on computer endpoint example: https://mdirss.jamfcloud.com/JSSResource/computers/id/2699
##test name attribute too when made
##endpoint is id/$id .. you can't use serial so use previous script to get values
##GET call- return loan status
#curl -sku $credentials $jamfProUrl/JSSResource/computers/id/$deviceID -H "accept: text/xml" | xmllint --xpath "computer/extension_attributes/extension_attribute/name" -


##this needs to be changed to computer endpoint: https://mdirss.jamfcloud.com/JSSResource/computers/id/2699

#Changes loan status to chosen selection from loanOption
curl -u $credentials $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value>$loanOption</value></extension_attribute></extension_attributes></computer>"

#Changes userName to selection from $userName
curl -u $credentials $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value>$userName</value></extension_attribute></extension_attributes></computer>"

#give user status update
if [[ $loanOption != "Ready to Loan" ]]
then
osascript << EOF
display dialog "$serialNumber checked out to $userName and placed in $loanOption group" buttons {"OK"} default button 1
EOF
else
osascript << EOF
display dialog "$serialNumber returned to the $loanOption group" buttons {"OK"} default button 1
EOF
fi

#you should write a companion policy to check the user out on logout
#literally just grab credentials (id parts of this script) and return to pile on logout

#this works as long as checkout script always happens on login

#need to implement a way to force users to run this. Maybe just agressive recurrence if params empty?

#make dialogue screen unskippable?

#base features working... should you remove ready to loan option and instead implement the second policy to return?

#need to remove cancel button as this isn't an optional process... if cancel hit then breaks program currently

#need to error handle to at least ensure that the user name is filled in with something

loanOptionTest=$(osascript << EOF
try
    with timeout of 3600 seconds -- Wait up to an hour before timing out.
            activate
            repeat
                set loanOptions to choose from list {"Staff", "Student", "Substitute Teacher"} with title "Choose from list" with prompt "Select User Type:" OK button name "Select" cancel button name "Cancel"
                if loanOptions is false then
                    beep
                    display dialog "Please Choose a User Type" buttons {"OK"} default button 1
                else
                    exit repeat
                end if
            end repeat
            loanOptions
    end timeout
end try
EOF
)
echo $loanOptionTest
