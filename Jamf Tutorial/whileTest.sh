#!/bin/bash

blocksDriven=0

while [[ $blocksDriven < 5 ]]
do
(( blocksDriven+=1 ))
if [[ $blocksDriven == 1 ]]
then
echo "you've driven $blocksDriven block"
sleep 1
else
echo "you've driven $blocksDriven blocks"
sleep 1
fi
done

