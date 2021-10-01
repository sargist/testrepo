#!/bin/bash

usage() { echo "Usage: $0 [-c <companyId>] [-s <ServiceName>] [-d <Date>] [-j <Json Client Detailes>]" 1>&2; exit 1; }

while getopts ":c:s:d:j:" o; do
    case "${o}" in
        c)
            companyId=${OPTARG}
            ;;
        s)
            serviceName=${OPTARG}
            ;;
		d)
            date=${OPTARG}
            ;;	
		j)
            clientJson=${OPTARG}
            ;;		
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${companyId}" ] || [ -z "${serviceName}" ] || [ -z "${date}" ] || [ -z "${clientJson}" ]; then
    usage
fi

servicis=$(curl --request GET https://zelda.bookingbug.com/api/v1/${companyId}/services --header 'App-Id: 6620ce3b529681b020e343206e9229822a4d77c7ec26')
servicisLength=$(echo $servicis | jq -r ._embedded.services | jq length)

for (( c=0; c<$servicisLength; c++ ))
do
	name=$(echo $servicis | jq -r ._embedded.services[$c].name)
	if [ name=="${serviceName}" ]; then
		service_id=$(echo $servicis | jq -r ._embedded.services[$c].id)
	fi
done

fname=$(echo $clientJson | jq .first_name | sed -e 's/\"//g')
lname=$(echo $clientJson | jq .last_name | sed -e 's/\"//g')
email=$(echo $clientJson | jq .email | sed -e 's/\"//g')
people=$(curl --request GET https://zelda.bookingbug.com/api/v1/${companyId}/people --header 'App-Id: 6620ce3b529681b020e343206e9229822a4d77c7ec26')
peopleLength=$(echo $people | jq -r ._embedded.people | jq length)

for (( c=0; c<$peopleLength; c++ ))
do
	name=$(echo $people | jq -r ._embedded.people[$c].name)
	if [[ "$name" == *"$fname"* ]] && [[ "$name" == *"$lname"* ]]; then
		people_id=$(echo $people | jq -r ._embedded.people[$c].id)
	fi
done


curl --location --request POST "https://zelda.bookingbug.com/api/v1/${companyId}/bookings" \
--header 'App-Id: 6620ce3b529681b020e343206e9229822a4d77c7ec26' \
--data-raw '{
"datetime":\"'"$issueId"'\","service_id":\"'"$service_id"'\","person_id":\"'"$people_id"'\","client[first_name]":\"'"$fname"'\","client[last_name]":\"'"$lname"'\","client[email]":\"'"$email"'\"
}'