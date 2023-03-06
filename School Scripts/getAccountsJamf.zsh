#!/bin/zsh

#creds=tbrown:Knothole11

#curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -u tbrown | xmllint --xpath "accounts/users/user/name/text()" -
#res=$?
#if test "$res" != "0"; then
#   echo "the curl command failed with: $res"
#fi

## Following is not really necessary. Cancel returns 1 and OK 0 ...
#if button returned of theResp is "Cancel" then
#   return 1
#end if
#EOF
#
## Check status of osascript
#if [ "$?" != "0" ] ; then
#   echo "User aborted. Exiting..."
#   exit 1
#fi
#
##-- other bash stuff here
#echo "All good, moving on...."



#curl -sku tbrown:Knothole11 https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/DMPPX9LQFK11 -H "accept: text/xml" | xmllint --xpath "mobile_device/extension_attributes/extension_attribute" -

#curl -fu tbrown:Knothole11 https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/DMPPX9LQFK11 -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>1</id><value>Ready To Loan</value></extension_attribute></extension_attributes></mobile_device>"

#curl -fu tbrown:Knothole11 https://mdirss.jamfcloud.com/JSSResource/mobiledevices/serialnumber/DMPPX9LQFK11 -H "content-type: text/xml" -X PUT -d "<mobile_device><extension_attributes><extension_attribute><id>2</id><value>Test User</value></extension_attribute></extension_attributes></mobile_device>"

jamfAccountList=$(curl -X GET "https://mdirss.jamfcloud.com/JSSResource/accounts" -H "accept: application/xml" -fsu tbrown:Knothole11 | xmllint --xpath "accounts/users/user/name/text()" -)
echo $jamfAccountList

function accountContains ()
{
  [[ $jamfAccountList =~ (^|[[:space:]])$1($|[[:space:]]) ]] && myResult=0 || myResult=1
}
#call function to set myResult 0=serial found 1=serial not found
username=tbrown
accountContains $username
echo $myResult
