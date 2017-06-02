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
  "build_num":$CIRCLE_BUILD_NUM,
  "time":"$(date +'%Y/%m/%d %I:%M:%S')",
  "benchmarks": {
    "cpu":$cpu,
    "io":$io,
    "mysql_total_req":$mysql_total,
    "mysql_read_req":$mysql_read,
    "mysql_write_req":$mysql_write,
    "mysql_other_req":$mysql_other
  }
}
EOF
