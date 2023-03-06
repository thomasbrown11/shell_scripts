# Get the currently logged in user 
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
echo $currentUser
 
# Global check if there is a user logged in 
if [ -z "$currentUser" -o "$currentUser" = "loginwindow" ]; then 
  echo "no user logged in, cannot proceed"  
  exit 1  
fi  
 
# Get the current user's UID 
uid=$(id -u "$currentUser")
echo $uid

runAsUser() {
  if [ "$currentUser" != "loginwindow" ]; then
    launchctl asuser "$uid" sudo -u "$currentUser" "$@"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
#     exit 1
  fi
}

#tDate=$(date %Y-%m-%dT%TZ)
#echo tDate $tDate
#
#do shell script "defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool TRUE;
#
#defaults -currentHost write com.apple.notificationcenterui doNotDisturbDate -date " & tDate & "
#
#osascript -e 'quit application \"NotificationCenter\" ' && killall usernoted" --this  set 'Do not disturb'  to true in the pref

#defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool TRUE
#echo $?
#defaults -currentHost write com.apple.notificationcenterui doNotDisturb -bool FALSE
#echo $?

MAC_UUID=$(system_profiler SPHardwareDataType | awk -F" " '/UUID/{print $3}');
echo $MAC_UUID

#does nothing?

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict> <key>dndEnd</key> <real>1439</real> <key>dndStart</key> <real>0.0</real> <key>doNotDisturb</key> <false/>
</dict>
</plist>
