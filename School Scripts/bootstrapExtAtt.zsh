#!/bin/zsh

hasBoots=$(sudo profiles status -type bootstraptoken)
echo $hasBoots

if [[ $hasBoots == *"YES"* ]]
then
echo "True"
else
echo "False"
fi

#sudo profiles status -type bootstraptoken
