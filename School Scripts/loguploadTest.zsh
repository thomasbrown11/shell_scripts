#!/bin/zsh

###Generate Bearer Token###
Basic=removed
BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $Basic")
echo "successful generation of bearer token: $BEARER"

OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
echo $OSversion

if [[ $OSversion < 13 ]]
then
api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
else
api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
fi
###################################
echo $api_token

#These values change per user, pull from script
username="Random User"
serialNumber=test_serial

#these values can stay
borrowTime=$(date +"%m%d%y")
borrower=$username
borrowTmpLocation="/var/tmp/borrowLog"
mkdir $borrowTmpLocation

#change for return log
filename=${borrower}_${borrowTime}_borrowed

#Create Borrower log
#change for return log
#serial included for the upload to admin computer
cat > "$borrowTmpLocation/$filename.text" << EOF
Borrowed by: $borrower on $(date)
S/N: $serialNumber
EOF

cd $borrowTmpLocation/ && zip -r $borrowTmpLocation/$filename.zip ./* && cd -

echo $(curl -k -H "Authorization: Bearer $api_token" https://mdirss.jamfcloud.com/JSSResource/fileuploads/computers/id/2699 -F name=@$borrowTmpLocation/$filename.zip)

#
## Cleanup files and remove tmp directory
echo "Cleaning Up"
rm -rf $borrowTmpLocation
