#osascript << EOF
#tell application “System Events”
#  log out
#end tell
##tell application “System Events”
##sleep
##end tell
#EOF

#osascript -e 'tell application "System Events"' -e 'log out' -e 'keystroke return' -e end

#prompt for borrowing/returning
chooseAction=$(osascript << EOF
display dialog "Log out, Wipe, or keep working?" buttons {"Log Out", "Keep Working", "Wipe"} default button 1
if the button returned of the result is "Log Out" then
    return "Log Out"
else if the button returned of the result is "Keep Working" then
    return "Keep Working"
else
    return "Wipe"
end if
EOF
)
#echo $chooseAction

if [[ $chooseAction == "Log Out" ]]
then
#osascript -e 'ignoring application responses' -e 'tell application "loginwindow" to «event aevtrlgo»' -e end
  echo "Log Out"
  exit 0
elif [[ $chooseAction == "Keep Working" ]]
  then
  echo "Keep Working"
exit 0
else
  echo "Wipe"
  exit 0
fi
