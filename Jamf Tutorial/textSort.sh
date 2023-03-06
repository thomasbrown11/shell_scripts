#!/bin/bash 

mkdir ~/Desktop/"textCopies"
sleep 1
folder=~/Desktop/textCopies

for i in ~/Downloads/*.text
do
cp "$i" $folder
echo "copying $i to textCopies..."
sleep 1 
done 
  

