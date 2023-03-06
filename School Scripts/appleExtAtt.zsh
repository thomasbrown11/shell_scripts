#!/bin/zsh 

if [[ -d /Library/Audio/Apple\ Loops/Apple ]]
then
  echo "<result>Yes</result>"
else
  echo "<result>No/result>"
  jamf policy -event AppleLoops
fi 
