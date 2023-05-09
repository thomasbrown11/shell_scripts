#!/bin/zsh

# Get username and password encoded in base64 format and stored as a variable in a script:
TOKEN=$(printf $1 | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)
echo $TOKEN
#running with current credentials made returned (you will need to run again to get 64-base if you change password


##This function takes in your actual basic token (the result of TOKEN) that you pass to https://mdirss.jamfcloud.com/api/v1/auth/token to get
#a temp Bearer Token (lasts 30 minutes)
#NEVER include with a script
function GenerateEncryptedString () {
    # Usage ~$ GenerateEncryptedString 
    local STRING="$TOKEN"
    echo $STRING
    local SALT=$(openssl rand -hex 8)
    local K=$(openssl rand -hex 12)
    local ENCRYPTED=$(echo "${STRING}" | openssl enc -aes256 -md md5 -a -A -S "${SALT}" -k "${K}")
    echo "Encrypted String: ${ENCRYPTED}"
    echo "Salt: ${SALT} | Passphrase: ${K}"
}

GenerateEncryptedString $TOKEN
#NOTE THAT THIS COULD BE DIFFERENT EVERY TIME SINCE Salt WILL RANDOMLY GENERATE... DecryptString will always decrypt back properly though

#
## Include DecryptString() with your script to decrypt the password sent by the JSS
## The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

# $1 is passed externally (change to $4 in actual call as this is the first available positional parameter in jamf) as the Encrypted String:
#Since the Salt (7cf8da22360f4311) and Passphrase (09de0192edd3e4caaf3cb796) are static This string always decodes properly without needing to actually pass the basic token into the script.
TOKEN=$(DecryptString $1 7cf8da22360f4311 09de0192edd3e4caaf3cb796)
echo "the token is $TOKEN"

# Alternative format for DecryptString function
#function DecryptString() {
#    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase(K)"
#    local SALT=$2
#    local K=$3
#    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "$SALT" -k "$K"
#}
#TOKEN=$(DecryptString $1 $2 $3)
#echo "the token is $TOKEN"
###

##################################################
#DIRECTIONS
#1.In Parameter box in jamf enter base64 returned value
#2.Near top of script include:
#function DecryptString() {
#    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
#}
#3.Now reference your actual credentials token with:
#TOKEN=$(DecryptString $4 7cf8da22360f4311 09de0192edd3e4caaf3cb796)
#*If someone actually takes the time to run DecryptString() separately with the parameter from jamf they will get base64 creds for bearer token request,
#they would then need to decode with a base64 decoder.. this is two layers of protection against JUST current admin.
##################################################

##generate new bearer token for jamf pro api calls... lasts 30 minutes
#BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
#echo $BEARER
#
#OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
#echo $OSversion
#
#if [[ $OSversion < 13 ]]
#then
#api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
#else
#api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
#fi
#echo $api_token

#!/bin/zsh

function DecryptString() {
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}
TOKEN=$(DecryptString $1 7cf8da22360f4311 09de0192edd3e4caaf3cb796)

BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
echo "successful generation of bearer token: $BEARER"

OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
echo $OSversion

if [[ $OSversion < 13 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
echo $api_token

