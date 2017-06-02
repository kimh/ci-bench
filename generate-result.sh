#!/bin/bash

set -ex

benchmark_dir="/tmp/benchmark"
cpu=$(grep "total time:" $benchmark_dir/cpu | awk '{printf "%f", $3}' | sed 's/s$//')
io=$(grep "total time:" $benchmark_dir/io | awk '{printf "%f", $3}' | sed 's/s$//')
mysql_read=$(grep "read:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
mysql_write=$(grep "write:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
mysql_other=$(grep "other:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
mysql_total=$(grep "total:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')

cat << EOF
{
  "platform":"$PLATFORM",
  "build_num":"$CIRCLE_BUILD_NUM",
  "time":"$(date +%s)",
  "result": {
    "cpu":"$cpu",
    "io":"$io",
    "mysql": {
      "read": "$mysql_read",
      "write": "$mysql_write",
      "other": "$mysql_other",
      "total": "$mysql_total"
    }
  }
}
EOF
