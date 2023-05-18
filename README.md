## 描叙
本工具用于在mac系统上，支持的功能有：
- 获取连接的手机设备列表
- 对ipa用Apple免费账号重签名
- 对ipa用Apple自有证书重签名

## 使用步骤

<!-- 1. 需要安装一个 Mail 插件，步骤如下： -->
<!-- 
- 下载 [MiniAppPlugin](https://dldir1.qq.com/WechatWebDev/donut/download/MiniAppPlugin.zip) 插件, 解压后将`MiniAppPlugin.mailbundle`放到`/Library/Mail/Bundles`目录下

- 打开`Mail`，到 菜单 邮件 -> 设置 -> 管理插件, 启动`MiniAppPlugin.mailbundle`插件，然后重启`Mail` -->

1. 下载[MiniAppBuilder](https://github.com/yujon/ipa-mac-builder/releases/)并解压

2. 将`iphone`手机用数据线连接到电脑上

3. 然后打开终端工具，执行以下命令，该命令将会从ipa重签名并安装到手机上

```sh
cd MiniappMacBuilder-xxx
# 获取连接的设备列表信息
./MiniAppBuilder --action getDevices 
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
```

> 首次采用免费证书签名时，需要安装一个mail插件，遇到以下提示时，请打开mail登录、启用MiniappBuilder插件并重启mail，然后保持mail打开。
<img width="1000" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/028a6e65-cd58-4fe2-b375-8812ea8a40ae">

<img width="1000" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/be291325-3429-415e-af12-cdb1a73cf08f">

<img width="1000" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/c7202eee-cef1-469a-824e-24a4d4f0df1c">

<img width="1000" alt="image" src="https://github.com/yujon/ipa-mac-builder/assets/16963584/25820f14-6c1e-44e2-ba64-56f327c69254">


4. 免费证书签名是，如果用的apple账号与手机登录的不同，需要到手机端打开：设置 -> 通用 -> VPN与设备管理，然后选择信任对应的签名apple账号
