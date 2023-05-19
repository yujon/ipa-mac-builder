#!/bin/bash

label="$1"
if [ "$2" = 'hide' ]; then
    answerType="with hidden answer"
else
    answerType=""
fi

# 唤起一个弹框输入
result=$(osascript -e 'Tell application "System Events" to display dialog "'"$label"'"  with title "Miniapp Builder" '"$answerType"' default answer "" buttons {"Cancel", "OK"} default button "OK"'  -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)

# 输出用户输入的内容
if [ "$result" = "Cancel" ]; then
    result=""
fi

echo "$result"
