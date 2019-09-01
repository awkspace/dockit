#!/bin/sh

if [ ! $(id -u) -eq 0 ]
then
    echo "The installer requires root privileges."
    echo "If you'd like to run dockit as a user, add the bin/ directory to your PATH."
    exit 1
fi

dir=$(dirname "$0")

cp $dir/bin/dockit /usr/local/bin/dockit
cp -r $dir/lib/dockit /usr/local/lib
