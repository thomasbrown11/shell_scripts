#!/bin/zsh
#DON'T BACKGROUND A WHILE LOOP. Eats around 7% of CPU just keeping this going
{
  while [[ $dsResult != 0 ]]
  do
  dscl . ls /Users | grep "MDIRSS Spare User"
  dsResult=$?
#  echo $dsResult
  done
  echo "All Done"
} &

#infinite loop as such
