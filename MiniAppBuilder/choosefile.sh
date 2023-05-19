#!/bin/bash

type=$1
title=$2
osascript <<EOF
set p12File to choose file with prompt "$title" of type {"$type"}

if p12File is not equal to false then
    set filePath to POSIX path of p12File
end if
EOF

echo $filePath