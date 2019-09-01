#!/bin/sh

setup() {

    dockit="$(cd $(dirname "$0")/../bin; pwd)/dockit"

    tmpdirs=$(mktemp)
    containers=$(mktemp)
    images=$(mktemp)

}

teardown() {

    rm -f $tmpdirs
    rm -f $containers
    rm -f $images

}

setup_testdir() {

    testdir=$(mktemp -d | tee -a $tmpdirs)

}

dock() {

    cd $testdir
    container=$(sh $dockit $@ 2>/dev/null)
    echo $container | tee -a $containers

}

build_image() {

    {
        cd $(dirname "$0")
        docker build -q -f $1 . | tee -a $images
    }

}

test_cleanup() {

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

    while read image
    do
        docker rmi -f $image >/dev/null
    done <$images
    printf '' > $images

}

run_test() {

    setup_testdir

    printf "$1... "

    output=$(set -e ; $2 2>&1)

    if [ $? -eq 0 ]
    then
        echo -e "\e[1m\e[92mPASS\e[0m"
    else
        echo -e "\e[1m\e[91mFAIL\e[0m"
        failed_tests="$failed_tests$1
---
$output
---

"
    fi

    test_cleanup

}

results() {

    if [ "$failed_tests" ]
    then
        echo
        echo "Test failures:"
        echo
        echo "$failed_tests"
        result=1
    else
        result=0
    fi
}

setup

name="Docked file has correct ownership in container"
_() {
    set -x
   
    touch $testdir/file
    chown -R 65534:65534 $testdir

    dock=$(dock -d alpine)

    ls=$(docker exec $dock ls -ln /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "0 0" ]
}
run_test "$name" _

name="Changes do not propagate to host"
_() {
    set -x

    touch $testdir/file1
    dock=$(dock -d alpine)

    docker exec $dock rm /docked/file1
    docker exec $dock touch /docked/file2

    docker exec $dock [ ! -f /docked/file1 ]
    docker exec $dock [ -f /docked/file2 ]
    [ -f $testdir/file1 ]
    [ ! -f $testdir/file2 ]
}
run_test "$name" _

name="Undocked file is present in host and container"
_() {
    set -x

    dock=$(dock -d alpine)

    docker exec $dock touch /docked/file
    docker exec $dock /bin/sh -c "cd /docked; undock file"

    docker exec $dock [ -f /docked/file ]
    [ -f $testdir/file ]
}
run_test "$name" _

name="Undocked file has correct ownership on host"
_() {
    set -x

    chown 65534:65534 $testdir
    dock=$(dock -d alpine)

    docker exec $dock touch /docked/file
    docker exec $dock /bin/sh -c "cd /docked; undock file"

    [ "$(ls -ln $testdir/file | awk '{print $3,$4}')" = "65534 65534" ]
}
run_test "$name" _

name="Dock as other user"
_() {
    set -x

    touch $testdir/file
    dock=$(dock -d -m 65534 alpine)

    ls=$(docker exec $dock ls -ln /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "65534 65534" ]
}
run_test "$name" _

name="Default to Docker USER"
_() {
    set -x

    touch $testdir/file

    img=$(build_image Dockerfile.withuser)
    dock=$(dock -d $img)

    ls=$(docker exec $dock ls -ln /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "1234 1234" ]
}
run_test "$name" _

results
teardown

exit $result
