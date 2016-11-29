#!/bin/bash

test ! -z $1 || { echo "USAGE: $0 <hostname>"; exit 1; }
hostname=$1
echo -n "Getting system_id for $hostname... "
system_id=$(maas $USER machines read | jq -r "map(select(.hostname == \"$hostname\")) | .[] | .system_id")
test ! -z $system_id && echo "$system_id" || { echo "error"; exit 1; }
echo -n "Allocating machine... "
maas $USER machines allocate system_id=$system_id > /dev/null && echo "success" || { echo "error"; exit 1; }
echo -n "Performing deployment... "
maas $USER machine deploy $system_id > /dev/null && echo "success" || { echo "error"; exit 1; }
