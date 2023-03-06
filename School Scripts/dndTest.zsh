#!/bin/zsh

#CURRENT_USER=$3 #jamf sets this parameter automatically so should be legit

CURRENT_USER=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )


cat << EOF > "/tmp/dnd_enable.sh"
#!/bin/sh
defaults -currentHost write 
~/Library/Preferences/ByHost/com.apple.notificationcenterui doNotDisturb 
-bool true
defaults -currentHost write 
~/Library/Preferences/ByHost/com.apple.notificationcenterui 
doNotDisturbDate -date "$(date)"
defaults -currentHost read 
~/Library/Preferences/ByHost/com.apple.notificationcenterui
killall -u "$CURRENT_USER" NotificationCenter
EOF

su - "$CURRENT_USER" "/tmp/dnd_enable.sh" 

rm -f "/tmp/dnd_enable.sh"

exit 0
