#!/bin/bash

set -ex

s3_bucket="s3://ci-bench2"
data_dir="./data"

function download_data() {
    local platform=$1
    local s3_path="$s3_bucket/circleci/$platform/"

    aws s3 cp $s3_path . --exclude="*" --include="result*" --recursive
}

function main() {
    local platform=$1
    local dir=$data_dir/$platform

    rm -rf $dir
    mkdir -p $dir
    pushd $dir
    download_data $platform
    merge_files
    popd
}

function merge_files() {
    cat result_*.json | jq -s '.' > data.json
}

main $1
