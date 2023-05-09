#!/bin/zsh

#the following separates the basic token (encoded base 64 version of user:password) into three parts... need to figure out
#two parts go in script, other is passed to $4 but not sure how
###
## Use 'openssl' to create an encrypted Base64 string for script parameters
## Additional layer of security when passing account credentials from the JSS to a client
#
## Use GenerateEncryptedString() locally - DO NOT include in the script!
## The 'Encrypted String' will become a parameter for the script in the JSS
## The unique 'Salt' and 'Passphrase' values will be present in your script


#function GenerateEncryptedString () {
#    # Usage ~$ GenerateEncryptedString REDACTED (convert user:pw to 64base string)
#    local STRING="${1}"
#    echo $STRING
#    local SALT=$(openssl rand -hex 8)
#    local K=$(openssl rand -hex 12)
#    local ENCRYPTED=$(echo "${STRING}" | openssl enc -aes256 -md md5 -a -A -S "${SALT}" -k "${K}")
#    echo "Encrypted String: ${ENCRYPTED}"
#    echo "Salt: ${SALT} | Passphrase: ${K}"
#}
#
#GenerateEncryptedString 

#Salt: 7cf8da22360f4311 | Passphrase: 09de0192edd3e4caaf3cb796

#
## Include DecryptString() with your script to decrypt the password sent by the JSS
## The 'Salt' and 'Passphrase' values would be present in the script
function DecryptString() {
    # Usage: ~$ DecryptString "Encrypted String" "Salt" "Passphrase"
    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "${2}" -k "${3}"
}

TOKEN=$(DecryptString $1 7cf8da22360f4311 09de0192edd3e4caaf3cb796)
echo "the token is $TOKEN"
#
## Alternative format for DecryptString function
#function DecryptString() {
#    # Usage: ~$ DecryptString "Encrypted String"
#    local SALT=""
#    local K=""
#    echo "${1}" | /usr/bin/openssl enc -aes256 -md md5 -d -a -A -S "$SALT" -k "$K"
#}
###



# Get username and password encoded in base64 format and stored as a variable in a script:
#TOKEN=$(printf username:password | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i -)



#TOKEN=REDACTED
#
##generate new token for jamf pro api calls... lasts 30 minutes
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
