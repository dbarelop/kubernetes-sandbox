#!/bin/bash

test ! -z $1 || { echo "USAGE: $0 [hostname ...]"; exit 1; }
while (( $# )); do
    hostname=$1
    shift
    echo -n "Getting system_id for $hostname... "
    system_id=$(maas $USER machines read | jq -r "map(select(.hostname == \"$hostname\")) | .[] | .system_id")
    test ! -z $system_id && echo "$system_id" || { echo "error"; continue; }
    echo -n "Releasing machine... "
    maas dbarelop machine release $system_id > /dev/null && echo "success" || { echo "error"; continue; }
done
