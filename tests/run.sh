#!/bin/sh

function cleanup() {

    echo "CLEANUP"
    echo "-------"

    if [ "$tmpdir" ]
    then
        echo "Deleting temporary directory: $tmpdir"
        rm -rf $tmpdir
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

tmpdir=$(mktemp -d)
containers=$(mktemp)

touch $tmpdir/file
chown -R nobody:nobody $tmpdir

test_start "Docked file has correct ownership"
(
    set -e
   
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

cleanup 0
