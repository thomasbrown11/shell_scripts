#!/bin/zsh

###TRAPS#########################
#traps to guarantee background process kill and temp files removed
#triggered on script exit (success)
#still runs on error to restart computer if fail (will probably get returned to admin)
# to exit on error thrown as well include: trap "exit" INT TERM ERR rather than next line
#INT refers to a CTR+C stop, ERR is any error
trap "exit" TERM
borrowTmpLocation=/var/tmp/borrowLog #variable incorrect
returnTmpLocation=/var/tmp/returnLog #varible incorrect
trap "rm -rf $borrowTmpLocation; rm -rf $returnTmpLocation; kill 0" EXIT
#################################

###Background process to kill computer after 5 minutes####
{
#  sleep 300 #sleep 5 minutes
#  shutdown -r now
  sleep 100
  echo "didn't work"
  exit 0
} &
##########################################################

##MDIRSS jamf cloud
jamfProUrl=https://mdirss.jamfcloud.com
#
##get serial and print
serialNumber=$(system_profiler SPHardwareDataType | awk '/Serial Number/{print $4}')
echo serialNumber $serialNumber

#

####################GENERATE BEARER TOKEN FOR API CALLS
#include encryption process at end (bearerTest.zsh)
#basic
#TOKEN=REMOVED

function DecryptString() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

TOKEN=$(DecryptString $1 7cf8da22360f4311 09de0192edd3e4caaf3cb796) #change $1 to $4 for deployment insert REMOVED at box

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
##########################################################

##get device id and print
deviceID=$(curl -sk -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/${serialNumber}" | xmllint --xpath '//general/id/text()' -)
echo deviceID $deviceID

##get jamfUser (tech integrator or admin) device id to send logs
#have users add their device's S/N in the second parameter box of their version of the policy
#adminLogID=$(curl -sk -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/$5" | xmllint --xpath '//general/id/text()' -)
#echo adminLogID $adminLogID

#for testing
adminLogID=$(curl -sk -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/C02FN2PSQ05P" | xmllint --xpath '//general/id/text()' -)
echo adminLogID $adminLogID

#prompt for borrowing/returning
chooseAction=$(osascript << EOF
display dialog "Are you borrowing or returning a this device?\n(if still borrowing hit Borrowing)" buttons {"Borrowing", "Returning"} default button 1
if the button returned of the result is "Borrowing" then
    return "Borrowing"
else
    return "Returning"
end if
EOF
)
echo $chooseAction

###FOR RETURNING COMPUTER#########################################################################
if [[ $chooseAction == "Returning" ]]
then

#get all MDIRSS jamf users
jamfAccountList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -fs -H "Authorization: Bearer $api_token" | xmllint --xpath "accounts/users/user/name/text()" -)
echo $jamfAccountList

#authenticate jamf user
while [[ $accountResult != 0 ]]
do

#get jamf username
jamfUser=$(osascript << EOF
text returned of (display dialog "Please enter JAMF username within 1 minute or \ncomputer will shut down.\n\nHitting Cancel will also initiate a shut down" default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
)
# Check status of osascript, exit script if "Cancel" selected
# necessary to break loop
if [ "$?" != "0" ] ; then
   echo "Computer Shutting Down" #actually logging out... does this mess up next log in?
   exit 1 #change to computer shutdown
fi
echo $jamfUser

function accountContains ()
{
  [[ $jamfAccountList == *$1* && $1 != "" ]] && accountResult=0 || accountResult=1
}
#call function to set myResult 0=jamfUser found 1=jamfUser not found
accountContains $jamfUser
echo acountResult $accountResult

if [[ $accountResult != 0 ]]
then
osascript << EOF
display dialog "Jamf username not found. Please try again." buttons {"OK"} default button 1
EOF
#exit 1
fi
done

#Returns device to Ready To Loan group
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value>Ready to Loan</value></extension_attribute></extension_attributes></computer>"

#Wipes username ext att
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value></value></extension_attribute></extension_attributes></computer>"

###return log actions

#set variables for return log
returnTime=$(date +"%m%d%y")
#returnTmpLocation="/var/tmp/returnLog"
mkdir $returnTmpLocation
filename=${jamfUser}_${returnTime}_returned_${serialNumber}

#Create return log
cat > "$returnTmpLocation/$filename.text" << EOF
Returned by: $jamfUser on $(date)
S/N: $serialNumber
EOF

#zip log
cd $returnTmpLocation/ && zip -r $returnTmpLocation/$filename.zip ./* && cd -

#send to user computer log
curl -sk -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/fileuploads/computers/id/$deviceID -F name=@$returnTmpLocation/$filename.zip

#send to jamfUser location at $5
curl -sk -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/fileuploads/computers/id/$adminLogID -F name=@$returnTmpLocation/$filename.zip

#echo "Cleaning Up"
#rm -rf $returnTmpLocation

#shutdown computer
osascript << EOF
display dialog "Computer shutting down..." buttons {"OK"} default button 1
EOF
#sudo shutdown -h now

#kill script
exit 0
fi
#######################################################################################

#If borrowing, continue

#If already checked out then allow user to continue with welcome back message
checkExtAtt=$(curl -X GET "$jamfProUrl/JSSResource/computers/id/$deviceID" -H "accept: application/xml" -H "Authorization: Bearer $api_token" | xmllint --xpath "computer/extension_attributes/extension_attribute[id=11]/value/text()" -)

if [[ $checkExtAtt != "" ]]
then
osascript << EOF
display dialog "Welcome Back, $checkExtAtt" buttons {"OK"} default button 1
EOF
exit 0
fi

#If borrowing from loaner pool (not already checked out)

#loanOption=$(osascript << EOF
#try
#    with timeout of 3600 seconds -- Wait up to an hour before timing out.
#            activate
#            repeat
#                set loanOptions to choose from list {"Staff", "Student", "Substitute Teacher"} with title "Choose from list" with prompt "Select User Type:" OK button name "Select" cancel button name "Cancel"
#                if loanOptions is false then
#                    beep
#                    display dialog "Please Choose a User Type" buttons {"OK"} default button 1
#                else
#                    exit repeat
#                end if
#            end repeat
#            loanOptions
#    end timeout
#end try
#EOF
#)
#echo loanOption $loanOption

#12/6.... this should return to previous menu instead? actually not so bad.. could just exit and run policy again based on custom trigger?

loanOption=$(osascript << EOF
try
    with timeout of 3600 seconds -- Wait up to an hour before timing out.
            activate
            repeat
                set loanOptions to choose from list {"Staff", "Student", "Substitute Teacher"} with title "Choose from list" with prompt "Select User Type:" OK button name "Select" cancel button name "Cancel"
                if loanOptions is false then
                    beep
                    exit repeat
                else
                    exit repeat
                end if
            end repeat
            loanOptions
    end timeout
end try
EOF
)
echo loanOption $loanOption

if [[ $loanOption == false ]]
then
#jamf policy -event funcBackUp <- this doesn't work... maybe something with triggering current policy?
zsh /Users/thomasbrown/Desktop/shell\ scripts/School\ Scripts/test.zsh U2FsdGVkX198+NoiNg9DEZ67T+Ua0LNJR5FM6ynfYXqxb0RplAOzEs/XgOqYa/sKQKws2O0C5QPkgekf0Y7VDw==
exit 0
fi

#Error handle to prevent userName being left blank
while [[ $userFilled != 0 ]]
do

#prompt for userName
userName=$(osascript << EOF
text returned of (display dialog "Please enter borrower first and last name" default answer "" buttons {"Continue"} default button "Continue")
EOF
)
echo $userName

#check that userName doesn't match empty string
#if [[ "$STR" == *"$SUB"* ]]
function filledUser ()
{
  [[ $userName == "" ]] && userFilled=1 || userFilled=0
}
#call function to set myResult 0=username filled 1=username not filled
filledUser $username
echo $userFilled

#if userName was empty
if [[ $userFilled != 0 ]]
then
osascript << EOF
display dialog "A first and last name must be entered" buttons {"OK"} default button 1
EOF
#exit 1
fi
done

osascript << EOF
display dialog "Changing $serialNumber user status to $loanOption" buttons {"OK"} default button 1
EOF

#Changes loan status to chosen selection from loanOption
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value>$loanOption</value></extension_attribute></extension_attributes></computer>"

#Changes userName to selection from $userName
curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value>$userName</value></extension_attribute></extension_attributes></computer>"

#give user status update
osascript << EOF
display dialog "$serialNumber checked out to $userName and placed in $loanOption group" buttons {"OK"} default button 1
EOF

###borrow log actions

#set variables for borrow log
borrowTime=$(date +"%m%d%y")
borrowTmpLocation="/var/tmp/borrowLog"
mkdir $borrowTmpLocation
filename=${userName}_${borrowTime}_borrowed_${serialNumber}

#Create return log
cat > "$borrowTmpLocation/$filename.text" << EOF
Borrowed by: $userName on $(date)
S/N: $serialNumber
EOF

#zip log
cd $borrowTmpLocation/ && zip -r $borrowTmpLocation/$filename.zip ./* && cd -

#send to user computer log
curl -sk -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/fileuploads/computers/id/$deviceID -F name=@$borrowTmpLocation/$filename.zip

#send to jamf admin computer log (tech integrator or admin)
curl -sk -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/fileuploads/computers/id/$adminLogID -F name=@$borrowTmpLocation/$filename.zip

#send to jamfUser location?

#echo "Cleaning Up"
#rm -rf $borrowTmpLocation



#force user interaction?
