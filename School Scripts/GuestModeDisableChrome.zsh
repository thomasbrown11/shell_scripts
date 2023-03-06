#!/bin/zsh


# Variable for current user definition

consoleuser=ls -l /dev/console | cut -d " " -f4

# Run command as current user 
su - "${consoleuser}" -c 

#Disable guest mode in Chrome

Defaults write com.google.Chrome BrowserGuestModeEnables -bool false

#Disable guest mode in Chrome

#Pause for 3 seconds

sleep 3 

#Quits Chrome
killall "Google Chrome"


