user=$(dscl . ls \Users | grep "Test User")
echo $user

#Run background process with no hangup (hopefully keeps running on logout)
nohup {
#log out current user
osascript -e 'ignoring application responses' -e 'tell application "loginwindow" to «event aevtrlgo»' -e end
#delete user
#sudo dscl . delete /users/$user
#echo output
#echo $?
#delete home folder of deleted user
#sudo rm -rf /users/testuser
#echo output
#echo $?
mkdir /Users/teacherspare/Desktop/testDirect
sudo shutdown -r now
} &
