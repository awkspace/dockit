#!/bin/sh

setup() {

    dockit="$(cd $(dirname "$0")/../bin; pwd)/dockit"

    tmpdirs=$(mktemp)
    containers=$(mktemp)
    images=$(mktemp)

    [ -f /sys/module/overlay/parameters/metacopy ] && metacopy=1

}

teardown() {

    rm -f $tmpdirs
    rm -f $containers
    rm -f $images

}

setup_testdir() {

    case "$OSTYPE" in
        darwin*)
            testdir=$(mktemp -d /tmp/tmp.XXXXXXXXXX | tee -a $tmpdirs)
            ;;
        *)
            testdir=$(mktemp -d | tee -a $tmpdirs)
            ;;
    esac

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
        docker stop -t 0 $container >/dev/null
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
        printf "\e[1m\e[32mPASS\e[0m\n"
    else
        printf "\e[1m\e[31mFAIL\e[0m\n"
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
    [ "$(id -u)" -eq 0 ] && chown -R 65534:65534 $testdir

    dock=$(dock -d alpine)

    ls=$(docker exec $dock ls -ln /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "0 0" ]
}
[ "$metacopy" ] && run_test "$name" _

name="Changes in /docked do not propagate to host"
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

    docker exec "$dock" mkdir /docked/dir
    docker exec "$dock" /bin/sh -c 'echo "hello world" > /docked/dir/file'
    docker exec "$dock" undock /docked/dir/file

    docker exec "$dock" apk add tree
    docker exec "$dock" tree /host
    docker exec "$dock" tree /docked
    docker exec "$dock" [ -f /docked/dir/file ]
    [ -f "$testdir/dir/file" ]
    [ "$(cat "$testdir/dir/file")" = "hello world" ]
}
run_test "$name" _

name="Undocked file has correct ownership on host"
_() {
    set -x

    if [ "$(id -u)" -eq 0 ]
    then
        host_user=65534
        host_group=65534
    else
        host_user="$(id -u)"
        host_group="$(id -g)"
    fi

    chown -R $host_user:$host_group $testdir
    dock=$(dock -d alpine)

    docker exec $dock touch /docked/file
    docker exec $dock undock /docked/file

    owner=$(ls -ln $testdir/file | awk '{print $3,$4}')
    [ "$owner" = "$host_user $host_group" ]
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
[ "$metacopy" ] && run_test "$name" _

name="Default to Docker USER"
_() {
    set -x

    touch $testdir/file

    img=$(build_image Dockerfile.withuser)
    dock=$(dock -d $img)

    ls=$(docker exec $dock ls -ln /docked/file)
    [ "$(echo $ls | awk '{print $3,$4}')" = "1234 1234" ]
}
[ "$metacopy" ] && run_test "$name" _

name="Skip mount"
_() {
    set -x

    dock=$(dock -n -d alpine)
    ! docker exec "$dock" ls /docked
}
run_test "$name" _

name="Respect VCS ignores"
_() {
    set -x

    touch $testdir/file.keep
    touch $testdir/file.ignore
    touch $testdir/ignoreme

    mkdir $testdir/ignoredir
    touch $testdir/ignoredir/file

    echo '*.ignore' >> $testdir/.gitignore
    echo 'ignoreme' >> $testdir/.gitignore
    echo "ignoredir/" >> $testdir/.gitignore

    dock=$(dock -d alpine)
    docker exec "$dock" [ -f /docked/file.keep ]
    docker exec "$dock" [ ! -f /docked/file.ignore ]
    [ -f "$testdir/file.ignore" ]
    docker exec "$dock" [ ! -f /docked/ignoreme ]
    [ -f "$testdir/ignoreme" ]
    docker exec "$dock" [ ! -d /docked/ignoredir ]
    [ -d "$testdir/ignoredir" ]
    [ -f "$testdir/ignoredir/file" ]
}
run_test "$name" _

results
teardown

exit $result
