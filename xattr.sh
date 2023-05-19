#!/bin/bash

# 递归查找所有层级目录下的 framework
find . -name "*.framework" -type d | while read framework; do
    echo "xattr $framework"
    # 执行 xattr 命令
    sudo xattr -r -d com.apple.quarantine "$framework"
done