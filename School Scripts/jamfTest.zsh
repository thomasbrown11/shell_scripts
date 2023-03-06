#!/bin/zsh

#TOKEN=dGJyb3duOnNlY3JldFBhc3N3b3JkMTI=
#
#BEARER=$(curl -X POST "https://mdirss.jamfcloud.com/api/v1/auth/token" -H "accept: application/json" -H "Authorization: Basic $TOKEN")
#
#echo bearer $BEARER
#
##get OSversion on user computer
#OSversion=$(/usr/bin/sw_vers -productVersion | awk -F . '{print $1}')
##echo $OSversion
#
##parse BEARER JSON based on current version to set api_token to usable auth token
#if [[ $OSversion < 13 ]]
#then
#api_token=$(/usr/bin/awk -F \" 'NR==2{print $4)' <<< "$BEARER" | /usr/bin/xargs)
#else
#api_token=$(/usr/bin/plutil -extract token raw -o - - <<< "$BEARER")
#fi
#echo api_token $api_token
#
ID=3743

token=eyJhbGciOiJIUzI1NiJ9.eyJhdXRoZW50aWNhdGVkLWFwcCI6IkdFTkVSSUMiLCJhdXRoZW50aWNhdGlvbi10eXBlIjoiSlNTIiwiZ3JvdXBzIjpbXSwic3ViamVjdC10eXBlIjoiSlNTX1VTRVJfSUQiLCJ0b2tlbi11dWlkIjoiMjg4ZjRhMWQtOGNhNC00NGZhLWFhZGUtNmNmYzU4MzQ3OGM2IiwibGRhcC1zZXJ2ZXItaWQiOi0xLCJzdWIiOiIxOCIsImV4cCI6MTY3MDUyODEzN30.rkDYQELQilKJeeA90ETxI2rbKJ6OOZ3ihQNcdqbJm7E

curl -X POST "https://mdirss.jamfcloud.com/api/v1/macos-managed-software-updates/send-updates" -H "accept: application/json" -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "{\"deviceIds\":[\"$ID\"],\"skipVersionVerification\":true,\"applyMajorUpdate\":true,\"InstallAction\":\"InstallForceRestart\":true,\"priority\":\"HIGH\"}"

