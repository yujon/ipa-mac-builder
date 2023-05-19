#!/bin/bash

# 选择证书路径
certificatePath=$(osascript -e 'set p12File to choose file with prompt "请选择 Apple 签名证书（p12文件）" of type {"p12"}' -e 'if p12File is not equal to false then' -e 'set certificatePath to POSIX path of p12File' -e 'end if' 2>/dev/null)


# 如果用户输入了证书，才会要求输入密码和选择profile
if [ "$certificatePath" != '' ]; then
    certificatePassword=$(osascript -e 'Tell application "System Events" to display dialog "请输入证书密码:"  with title "Miniapp Builder" with hidden answer default answer "" buttons {"Cancel", "OK"} default button "OK"' -e 'if button returned of result is "OK" then' -e 'text returned of result' -e 'else' -e 'return "Cancel"' -e 'end if' 2>/dev/null)
    # 输入密码
    if [ "$certificatePassword" != 'Cancel' ]; then 
        # 选择profile
        profilePath=$(osascript -e 'set profilePath to choose file with prompt "请选择 profile 文件（mobileprovision文件）" of type {"mobileprovision"}' -e 'if profilePath is not equal to false then' -e 'set profilePath to POSIX path of profilePath' -e 'end if' 2>/dev/null)
        if [ "$certificatePassword" != 'Cancel' ]; then 
            remember=$(osascript -e 'Tell application "System Events" to display dialog "记住选择的证书等配置（只保存于本地）？"  with title "Miniapp Builder"  buttons {"No", "Yes"} default button "Yes"' -e 'if button returned of result is "Yes" then' -e 'return "yes"' -e 'else' -e 'return "no"' -e 'end if' 2>/dev/null)
        else
            certificatePath=""
            certificatePassword=""
            profilePath=""
        fi
    else 
        certificatePath=""
        certificatePassword=""
    fi
else
    certificatePath=""
fi

echo "$certificatePath"
echo "$certificatePassword"
echo "$profilePath"
echo "$remember"