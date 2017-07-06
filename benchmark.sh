#!/bin/bash

set -ex

execution_time=10

function cpu_throughput {
    local time=$1
    local result_dir=$2

    echo "Running CPU benchmarking..."
    sysbench --time=$time cpu run  > $result_dir
}

function io_throughput {
    local time=$1
    local result_dir=$2

    echo "Running IO benchmarking..."
    sysbench fileio cleanup
    sysbench fileio prepare
    sysbench --file-test-mode=rndrw --max-time=$time fileio run > $result_dir
}

function mysql_throughput {
    local time=$1
    local result_dir=$2
    local oltp_lua="/usr/share/sysbench/tests/include/oltp_legacy/oltp.lua"

    echo "Running MySQL benchmarking..."
    mysqladmin -u root -h 127.0.0.1 create dbtest || true
    sysbench --test=$oltp_lua \
             --db-driver=mysql \
             --mysql-db=dbtest \
             --mysql-user=root \
             --mysql-host=127.0.0.1 \
             cleanup

    sysbench --test=$oltp_lua \
             --oltp-table-size=100000 \
             --db-driver=mysql \
             --mysql-db=dbtest \
             --mysql-user=root \
             --mysql-host=127.0.0.1 \
             prepare

    sysbench --test=$oltp_lua \
             --max-time=$time \
             --oltp-read-only=off \
             --oltp-table-size=100000 \
             --oltp-test-mode=complex \
             --num-threads=1 \
             --max-requests=0 \
             --db-driver=mysql \
             --mysql-db=dbtest \
             --mysql-user=root \
             --mysql-host=127.0.0.1 \
             run > $result_dir
}

function public_ip {
    if [ -v "CIRCLE_INTERNAL_CONFIG" ]; then
        echo -n $(jq -r .AdvertisedHostIp $CIRCLE_INTERNAL_CONFIG)
    else
        echo -n ""
    fi
}

function generate_result {
    local benchmark_dir=$1

    cpu=$(grep "total number of events:" $benchmark_dir/cpu | awk '{printf "%f", $5}' | sed 's/s$//')
    io=$(grep "total number of events:" $benchmark_dir/io | awk '{printf "%f", $5}' | sed 's/s$//')
    mysql_read=$(grep "read:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
    mysql_write=$(grep "write:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
    mysql_other=$(grep "other:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
    mysql_total=$(grep "total:" $benchmark_dir/mysql | awk '{printf "%f", $2}' | sed 's/s$//')
    db_migrate=$(cat $benchmark_dir/db_migrate)
    rspec=$(cat $benchmark_dir/rspec)

    cat << EOF
{
  "platform":"$PLATFORM",
  "build_num":$CIRCLE_BUILD_NUM,
  "time":"$(date +'%Y/%m/%d %H:%M:%S')",
  "ip":"$(public_ip)",
  "benchmarks": {
    "cpu":$cpu,
    "io":$io,
    "mysql_total_req":$mysql_total,
    "mysql_read_req":$mysql_read,
    "mysql_write_req":$mysql_write,
    "mysql_other_req":$mysql_other,
    "db_migrate":$db_migrate,
    "rspec":$rspec
  }
}
EOF
}

function upload_s3 {
    local branch=$1
    local s3_bucket=$2
    local s3_path=$s3_bucket/circleci/$branch/

    echo "Uploading benchmark result to $s3_path ....."
    aws s3 cp /tmp/benchmark/result_$CIRCLE_BUILD_NUM.json $s3_path
}

branch=$1
s3_bucket=$2
result_dir="/tmp/benchmark"

mkdir -p $result_dir

cpu_throughput $execution_time $result_dir/cpu
io_throughput $execution_time $result_dir/io
mysql_throughput $execution_time $result_dir/mysql

generate_result $result_dir > $result_dir/result_$CIRCLE_BUILD_NUM.json

echo "======== Benchmark Result =========="
cat $result_dir/result_$CIRCLE_BUILD_NUM.json | jq .

upload_s3 $branch $s3_bucket
