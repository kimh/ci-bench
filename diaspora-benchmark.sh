#!/bin/bash

function prepare {
    cd diaspora
    bin/bundle install --jobs $(nproc) --no-deployment --without production development --with postgresql --path vendor/bundle
}

function migration_benchmark {
    cd diaspora
    bash -c "time -p bin/rake db:create db:migrate" > /tmp/db_migrate.output 2>&1
    cat /tmp/db_migrate.output
    tail -3 /tmp/db_migrate.output | grep real | awk '{printf "%f", $2}' > /tmp/benchmark/db_migrate
}

function rspec_benchmark {
    cd diaspora
    bash -c "time -p BUILD_TYPE=other ./script/ci/build.sh" > /tmp/rspec.output 2>&1
    cat /tmp/rspec.output
    tail -3 /tmp/rspec.output | grep real | awk '{printf "%f", $2}' > /tmp/benchmark/rspec
}

mkdir -p /tmp/benchmark
prepare
migration_benchmark
rspec_benchmark
