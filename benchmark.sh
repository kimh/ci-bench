#!/bin/bash

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
    mysqladmin -u root -h 127.0.0.1 create dbtest
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
             --oltp-read-only=off \
             --oltp-table-size=100000 \
             --oltp-test-mode=complex \
             --num-threads=1 \
             --max-requests=0 \
             --max-time=60 \
             --db-driver=mysql \
             --mysql-db=dbtest \
             --mysql-user=root \
             --mysql-host=127.0.0.1 \
             run > $result_dir
}

function main {
    local time=$1
    local result_dir="/tmp/benchmark"

    mkdir -p $result_dir

    cpu_throughput $time $result_dir/cpu
    io_throughput $time $result_dir/io
    mysql_throughput $time $result_dir/mysql
}
