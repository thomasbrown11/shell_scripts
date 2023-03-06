#!/bin/bash 

while [[ -f /Users/thomasbrown/Desktop/bother.txt ]]
do
echo "prompting user"
osascript -e 'display dialog "test.txt still exists. Please delete from desktop" buttons {"OK"} default button 1'
sleep 5
done
