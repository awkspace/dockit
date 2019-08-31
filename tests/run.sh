#!/bin/sh

function cleanup() {

    echo "CLEANUP"
    echo "-------"

    if [ "$tmpdirs" ]
    then
        while read tmpdir
        do
            echo "Deleting temporary directory: $tmpdir"
            rm -rf $tmpdir
        done <$tmpdirs
    fi

    if [ "$containers" ]
    then
        while read container
        do
           echo "Deleting container: $container"
           docker rm -f $container >/dev/null
        done <$containers
        rm -f $containers
    fi

    exit $1

}

function test_start() {

    title="TEST: $1"
    len=$(expr length "$title")

    echo $title
    for i in $(seq $len)
    do
        printf "-"
    done
    echo

}

function test_result() {

    if [ $? -eq 0 ]
    then
        echo "PASS"
    else
        echo "FAIL"
    fi
    echo

}

dockit="$(cd $(dirname "$0")/../bin; pwd)/dockit"

tmpdirs=$(mktemp)
containers=$(mktemp)

test_start "Docked file has correct ownership"
(
    set -e

    tmpdir=$(mktemp -d)
    echo $tmpdir >> $tmpdirs

    touch $tmpdir/file
    chown -R nobody:nobody $tmpdir
   
    cd $tmpdir
    container=$(sh $dockit -d alpine 2>/dev/null)
    echo $container >> $containers

    ls=$(docker exec $container ls -l /docked/file)
    user=$(echo $ls | awk '{print $3}')
    group=$(echo $ls | awk '{print $4}')

    [ "$user" = "root" ]
    [ "$group" = "root" ]
)
test_result

test_start "Changes do not propagate to host"
(
    set -e

    tmpdir=$(mktemp -d)
    echo $tmpdir >> $tmpdirs

    touch $tmpdir/file1

    cd $tmpdir
    container=$(sh $dockit -d alpine 2>/dev/null)
    echo $container >> $containers

    docker exec $container rm /docked/file1
    docker exec $container touch /docked/file2

    docker exec $container [ ! -f /docked/file1 ]
    docker exec $container [ -f /docked/file2 ]
    [ -f $tmpdir/file1 ]
    [ ! -f $tmpdir/file2 ]
)
test_result

cleanup 0
