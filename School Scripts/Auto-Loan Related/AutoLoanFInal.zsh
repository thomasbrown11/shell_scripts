#!/bin/zsh

###TRAPS#########################
#traps to guarantee background process kill and temp files removed
#triggered on script exit (success)
#still runs on error to restart computer if fail (will probably get returned to admin)
# to exit on error thrown as well include: trap "exit" INT TERM ERR rather than next line
#INT refers to a CTR+C stop, ERR is any error
trap "exit" TERM
borrowTmpLocation=/var/tmp/borrowLog 
returnTmpLocation=/var/tmp/returnLog
trap "rm -rf $borrowTmpLocation; rm -rf $returnTmpLocation; kill 0" EXIT
#################################

###Background process to kill computer after 5 minutes####
{
  sleep 300 #wait 5 minutes while running script
  echo "time limit reached"
  shutdown -r now #restart now
} &
##########################################################

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

##first parameter removed for security purposes
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

##get jamfUser (tech integrator or admin) device id to send logs
#have users add their device's S/N in the second parameter box of their version of the policy
adminLogID=$(curl -k -H "Authorization: Bearer $api_token" -H "accept: application/xml" "$jamfProUrl/JSSResource/computers/serialnumber/C02FN2PSQ05P" | xmllint --xpath '//general/id/text()' -)
echo "your adminLogID is $adminLogID"

while [[ $notCanceled != true ]]
do
  #prompt for borrowing/returning########
    chooseAction=$(osascript << EOF
    display dialog "Are you borrowing or returning a this device?\n(if still borrowing hit Borrowing).\n\nWARNING-Computer will shutdown in 5 minutes if not complete." buttons {"Borrowing", "Returning"} default button 1
    if the button returned of the result is "Borrowing" then
        return "Borrowing"
    else
        return "Returning"
    end if
EOF
    )
    ######################################

    ###FOR RETURNING COMPUTER#########################################################################
    if [[ $chooseAction == "Returning" ]]
    then
        echo "you chose returning: $chooseAction" #REMOVE
        
        #get all MDIRSS jamf users
        jamfAccountList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -fs -H "Authorization: Bearer $api_token" | xmllint --xpath "accounts/users/user/name/text()" -)
        echo $jamfAccountList

        
        while [[ $accountResult != 0 ]]
        do
            jamfUser=$(osascript << EOF
            text returned of (display dialog "Please enter JAMF username within 1 minute or \ncomputer will shut down." default answer "" buttons {"Cancel", "Continue"} default button "Continue")
EOF
            )
            
            #if "Cancel" clicked trigger outer loop reiteration to return to Borrow/Return prompt
            if [ "$?" != "0" ] ; then
                continue 2
            fi
            
            function accountContains ()
            {
              [[ $jamfAccountList == *$1* && $1 != "" ]] && accountResult=0 || accountResult=1
            }
            #call function to set myResult 0=jamfUser found 1=jamfUser not found
            accountContains $jamfUser
#            accountResult=0 #this simulates a success
    
            if [[ $accountResult != 0 ]]
            then
                osascript << EOF
                display dialog "Jamf username not found. Please try again." buttons {"OK"} default button 1
EOF
            fi
        done
    
        #Returns device to Ready To Loan group
        curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>10</id><value>Ready to Loan</value></extension_attribute></extension_attributes></computer>"

        #Wipes username ext att
        curl -H "Authorization: Bearer $api_token" $jamfProUrl/JSSResource/computers/id/$deviceID -H "content-type: text/xml" -X PUT -d "<computer><extension_attributes><extension_attribute><id>11</id><value></value></extension_attribute></extension_attributes></computer>"

        ###return log actions

        #set variables for return log
        returnTime=$(date +"%m%d%y")
        returnTmpLocation="/var/tmp/returnLog"
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
            
        chooseAfterEvent=$(osascript << EOF
        display dialog "Log out, wipe, or keep working?" buttons {"Log Out", "Keep Working", "Wipe"} default button 1
        if the button returned of the result is "Log Out" then
            return "Log Out"
        else if the button returned of the result is "Keep Working" then
            return "Keep Working"
        else
            return "Wipe"
        end if
EOF
        )
        echo $chooseAfterEvent
       
        if [[ $chooseAfterEvent == "Log Out" ]]
            then
            osascript -e 'ignoring application responses' -e 'tell application "loginwindow" to «event aevtrlgo»' -e end
            echo "Log Out"
            exit 0
        elif [[ $chooseAfterEvent == "Keep Working" ]]
            then
            echo "Keep Working"
            exit 0
        else
            echo "Wipe"
            user=$(dscl . ls \Users | grep "MDIRSS Spare User")
            #log out current user
            osascript -e 'ignoring application responses' -e 'tell application "loginwindow" to «event aevtrlgo»' -e end
            sleep 3
            #delete user
            sudo dscl . delete /users/$user
            sleep 3
            #delete homefolder
            sudo rm -rf /users/MDIRSSspareuser
            sleep 30
            #add MDIRSS Spare User back by calling policy 529
            sudo jamf policy -id 529
            #set up test var
            dsResult=1 #maybe delete?
            #loop until MDIRSS Spare User is present on machine (policy 529 complete)
            while [[ $dsResult != 0 ]]
            do
                dscl . ls /Users | grep "MDIRSS Spare User"
                dsResult=$?
            done
            #once user present restart
            sudo shutdown -r now
            exit 0
        fi
    fi
    
    #If borrowing, continue
    #######################################################################################
    ###If already checked out then allow user to continue with welcome back message##############
    checkExtAtt=$(curl -X GET "$jamfProUrl/JSSResource/computers/id/$deviceID" -H "accept: application/xml" -H "Authorization: Bearer $api_token" | xmllint --xpath "computer/extension_attributes/extension_attribute[id=11]/value/text()" -)
    
    #checkExtAtt="Test User" #simulate a return login from borrower
    if [[ $checkExtAtt != "" ]]
    then
    osascript << EOF
    display dialog "Welcome Back, $checkExtAtt" buttons {"OK"} default button 1
EOF
    exit 0
    fi
    
    #If borrowing from loaner pool (not already checked out)
    loanOption=$(osascript << EOF
    try
        with timeout of 3600 seconds -- Wait up to an hour before timing out.
                activate
                repeat
                    set loanOptions to choose from list {"Staff", "Student", "Substitute Teacher"} with title "Choose from list" with prompt "Select User Type:" OK button name "Select" cancel button name "Cancel"
                    if loanOptions is false then
                        exit
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
    
    #loop back to borrow/return option if cancel hit
    if [[ $loanOption == false ]]
    then
        continue 2
    fi
    
    #Error handle to prevent userName being left blank
    while [[ $userFilled != 0 ]]
    do
        #prompt for userName
        userName=$(osascript << EOF
        text returned of (display dialog "Please enter borrower first and last name" default answer "" buttons {"Continue"} default button "Continue")
EOF
        )

        #check that userName doesn't match empty string
        function filledUser ()
        {
          [[ $userName == "" ]] && userFilled=1 || userFilled=0
        }
        #call function to set userFilled 0=username filled 1=username not filled
        filledUser $username

        #if userName was empty
        if [[ $userFilled != 0 ]]
        then
            osascript << EOF
            display dialog "A first and last name must be entered" buttons {"OK"} default button 1
EOF
        fi
    done
    echo $userName
    
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
    filename=${userName}_${borrowTime}_borrowed_$serialNumber

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
    exit 0
done

exit 0
