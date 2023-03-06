#!/bin/zsh

####Generate Bearer Token###
#Basic=dGJyb3duOnNlY3JldFBhc3N3b3JkMTI=
#BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $Basic")
#echo "successful generation of bearer token: $BEARER"
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
####################################
#echo $api_token

#
##These values change per user, pull from script
#username="Thomas Brown"
#serialNumber=test_serial
#
##these values can stay
#borrowTime=$(date +"%m%d%y")
#borrower=$username #this can be passed jamf user instead after auth
#borrowTmpLocation="/var/tmp/returnLog"
#mkdir $borrowTmpLocation
#
##change for return log
#filename=${borrower}_${borrowTime}_returned
#
##Create Borrower log
##change for return log
##serial included for the upload to admin computer
#cat > "$borrowTmpLocation/$filename.text" << EOF
#Returned by: $borrower on $(date)
#S/N: $serialNumber
#EOF
#
#cd $borrowTmpLocation/ && zip -r $borrowTmpLocation/$filename.zip ./* && cd -
#
#echo $(curl -k -H "Authorization: Bearer $api_token" https://mdirss.jamfcloud.com/JSSResource/fileuploads/computers/id/2699 -F name=@$borrowTmpLocation/$filename.zip)
#
##
### Cleanup files and remove tmp directory
#echo "Cleaning Up"
#rm -rf $borrowTmpLocation

jamfProUrl=https://mdirss.jamfcloud.com
deviceID=2699

#curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -fs -H "Authorization: Bearer $api_token" | xmllint --xpath "accounts/users/user/name/text()" -
#vari="Computer Loaned To"
#

api_token=eyJhbGciOiJIUzI1NiJ9.eyJhdXRoZW50aWNhdGVkLWFwcCI6IkdFTkVSSUMiLCJhdXRoZW50aWNhdGlvbi10eXBlIjoiSlNTIiwiZ3JvdXBzIjpbXSwic3ViamVjdC10eXBlIjoiSlNTX1VTRVJfSUQiLCJ0b2tlbi11dWlkIjoiMjkxM2FiMmYtYjU2Zi00YTQzLTgyN2EtNzIzNzUwZjUyNTVhIiwibGRhcC1zZXJ2ZXItaWQiOi0xLCJzdWIiOiIxOCIsImV4cCI6MTY2OTk5NDM3OH0.k44QmIakRZVx-r_VyG6FalK72hWzfhFVxLFmXtuTEbE


value=$(curl -X GET "$jamfProUrl/JSSResource/computers/id/2699" -H "accept: application/xml" -H "Authorization: Bearer $api_token" | xmllint --xpath "computer/extension_attributes/extension_attribute[id=11]" -)
echo $value


