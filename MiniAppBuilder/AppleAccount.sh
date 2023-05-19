#!/bin/bash

# 唤起一个弹框输入账号
username=$(osascript -e 'Tell application "System Events" to display dialog "请输入 Apple 账号(如是手机号前面+86):" with title "Miniapp Builder" default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)

# 如果用户输入了账号，才会要求输入密码
if [ "$username" != "Cancel" ]; then
    password=$(osascript -e 'Tell application "System Events" to display dialog "请输入 Apple 密码:"  with title "Miniapp Builder" with hidden answer default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)
    if [ "$password" = "Cancel" ]; then
        username=""
        password=""
    else 
        remember=$(osascript -e 'Tell application "System Events" to display dialog "记住账号密码（只保存于本地）？"  with title "Miniapp Builder"  buttons {"No", "Yes"} default button "Yes"' -e 'if button returned of result is "Yes" then' -e 'return "yes"' -e 'else' -e 'return "no"' -e 'end if' 2>/dev/null)
    fi
else
    username=""
fi

# 输出用户输入的账号和密码
echo "$username"
echo "$password"
echo "$remember"