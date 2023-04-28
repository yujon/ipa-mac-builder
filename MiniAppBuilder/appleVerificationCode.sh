#!/bin/bash

# 唤起一个弹框输入验证码
verificationCode=$(osascript -e 'Tell application "System Events" to display dialog "Please enter your verificationCode:"  with title "Miniapp Builder" default answer "" buttons {"Cancel", "OK"} default button "OK"'  -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)

# 输出用户输入的验证码
if [ "$verificationCode" = "Cancel" ]; then
    verificationCode=""
fi

echo "$verificationCode"