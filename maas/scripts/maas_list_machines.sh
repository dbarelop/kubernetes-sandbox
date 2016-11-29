#!/bin/bash

maas $USER machines read | jq -r '["system_id", "hostname", "cpu_count", "status_name"], ["---------", "--------", "---------", "-----------"], (.[] | [.system_id, .hostname, .cpu_count, .status_name]) | @csv' | sed -r 's/"//g' | column -s, -t
