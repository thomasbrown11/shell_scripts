#!/bin/bash

for folder in $(cat $1)
do
mkdir ~/Desktop/$folder
echo "You've made the folder $folder on your desktop"
done 

