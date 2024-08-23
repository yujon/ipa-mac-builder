# IPA Mac Builder

## 项目迁移说明
本项目迁移至新的地址，当前项目不再维护，请移至[这里](https://github.com/TIT-Frontend/ipa-mac-builder)


## Features 功能
本工具用于在mac系统上，支持的功能有：
- 获取连接的手机设备列表
- 对ipa用Apple免费账号重签名
- 对ipa用Apple自有证书重签名

## Usage 使用步骤 
1. 下载[MiniAppBuilder](https://github.com/yujon/ipa-mac-builder/releases/)并解压

2. 将`iphone`手机用数据线连接到电脑上

3. 然后打开终端工具，执行以下命令，该命令将会从ipa重签名并安装到手机上

```sh
cd MiniappMacBuilder-xxx
# 获取连接的设备列表信息
# ./MiniAppBuilder --action getDevices 
# 免费证书签名
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --install
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --appleId xxx --password xxx --install
# 自有证书签名
./MiniAppBuilder --action sign --type certificate --ipa {ipaPath} --certificatePath xxx --certificatePassword xxx --profilePath xxx --install
# 导出ipa
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --export /aaa/bbb/ccc
# 指定bundleId(默认为same，auto代表自动分配，xxxx是自定义的值)
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --bundleId same|auto|xxxx --install
# 指定entitlements(格式为A=xx&B=xxx，设置的每一项应该是bundleId已经具备的权限，否则会被过滤)
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} com.apple.developer.associated-domains=htpps://www.test.com/a/ --install
# 记住了我的选择（账密/证书）后，可以clear
# ./MiniAppBuilder --action clear
```

4. 免费证书签名是，如果用的apple账号与手机登录的不同，需要到手机端打开：设置 -> 通用 -> VPN与设备管理，然后选择信任对应的签名apple账号

## QA 常见问题
#### 问题1. mac上报framework已损坏

 <img width="400" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/2e62379f-edcb-4c0a-a69b-dd0fc9f3aabf">

解决方式： mac 系统上，系统设置-》隐私与安全性，选择信任 MiniappBuilder 程序

#### 问题2. mac上报framework已损坏

<img width="400" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/41eff07f-54e8-491e-a0ce-028adc652423">

解决方式： cd到解压出来的目录下，执行xattr.sh脚本

#### 问题3. ios上打开app提示开发者模式未开启

<img width="400" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/b7a478ff-91ec-4f3f-a7e8-d2965f6e9168">

解决方式： 需要到手机端打开：设置 ->  隐私与安全性 -> 开发者模式，开关打开即可

#### 问题4. ios上打开app提示不受信任的开发者

<img width="400" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/06d04145-483a-450d-80e8-be19fc4c6b0a">

解决方式： 需要到手机端打开：设置 -> 通用 -> VPN与设备管理，然后选择信任对应的签名apple账号


