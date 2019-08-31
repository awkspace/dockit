#!/bin/sh

function setup() {

    dockit="$(cd $(dirname "$0")/../bin; pwd)/dockit"

    tmpdirs=$(mktemp)
    containers=$(mktemp)

}

function teardown() {

    rm -f $tmpdirs
    rm -f $containers

}

function setup_testdir() {

    testdir=$(mktemp -d | tee -a $tmpdirs)

}

function dock() {

    cd $testdir
    container=$(sh $dockit $@ 2>/dev/null)
    echo $container | tee -a $containers

}

function test_cleanup() {

    while read tmpdir
    do
        rm -rf $tmpdir
    done <$tmpdirs
    printf '' > $tmpdirs

    while read container
    do
        docker rm -f $container >/dev/null
    done <$containers
    printf '' > $containers

}

function test_start() {

    setup_testdir
   
    title="TEST: $1"
    len=$(expr length "$title")

    echo $title
    for i in $(seq $len)
    do
        printf "-"
    done
    echo

}

function test_finish() {

    if [ $? -eq 0 ]
    then
        echo "PASS"
    else
        echo "FAIL"
    fi
    echo

    test_cleanup

}

setup

test_start "Docked file has correct ownership in container"
(
    set -e

    touch $testdir/file
    chown -R nobody:nobody $testdir
   
    dock=$(dock -d alpine)

    ls=$(docker exec $dock ls -l /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "root root" ]
)
test_finish

test_start "Changes do not propagate to host"
(
    set -e

    touch $testdir/file1
    dock=$(dock -d alpine)

    docker exec $dock rm /docked/file1
    docker exec $dock touch /docked/file2

    docker exec $dock [ ! -f /docked/file1 ]
    docker exec $dock [ -f /docked/file2 ]
    [ -f $testdir/file1 ]
    [ ! -f $testdir/file2 ]
)
test_finish

test_start "Undocked file is present in host and container"
(
    set -e

    dock=$(dock -d alpine)

    docker exec $dock touch /docked/file
    docker exec $dock /bin/sh -c "cd /docked; undock file"

    docker exec $dock [ -f /docked/file ]
    [ -f $testdir/file ]
)
test_finish

test_start "Undocked file has correct ownership on host"
(
    set -e

    chown nobody:nobody $testdir
    dock=$(dock -d alpine)

    docker exec $dock touch /docked/file
    docker exec $dock /bin/sh -c "cd /docked; undock file"

    [ "$(ls -l $testdir/file | awk '{print $3,$4}')" = "nobody nobody" ]
)
test_finish

teardown
