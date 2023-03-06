#!/bin/zsh

CURRENT_USER=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name 
:/ {print $3 $4 $5}')

#osascript << EOF
#display dialog "eligible for policy" buttons {"OK"} default button 1
#EOF

#osascript << EOF
#display dialog "currentUser is $CURRENT_USER" buttons {"OK"} default 
button 1
#EOF

if [[ $CURRENT_USER == "MDIRSSSpareUser" ]]
then
osascript -e 'tell application "Finder" to set desktop picture to 
POSIX file "/usr/local/Desktop/MDIRSS Spare.png"'
#osascript << EOF
#display dialog "eligible for policy" buttons {"OK"} default button 1
#EOF
fi 

exit 0
