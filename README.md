## 描叙
本工具用于在mac系统上，支持的功能有：
- 获取连接的手机设备列表
- 对ipa用Apple免费账号重签名
- 对ipa用Apple自有证书重签名

## 使用步骤

1. 需要安装一个 Mail 插件，步骤如下：

- 下载 [MiniAppPlugin](https://dldir1.qq.com/WechatWebDev/donut/download/MiniAppPlugin.zip) 插件, 解压后将`MiniAppPlugin.mailbundle`放到`/Library/Mail/Bundles`目录下

- 打开`Mail`，到 菜单 邮件 -> 设置 -> 管理插件, 启动`MiniAppPlugin.mailbundle`插件，然后重启`Mail`

2. 下载[MiniAppBuilder](https://github.com/yujon/ipa-mac-builder/releases/)并解压

3. 将`iphone`手机用数据线连接到电脑上

4. 然后打开终端工具，执行以下命令，该命令将会从ipa重签名并安装到手机上

```sh
cd MiniappMacBuilder-v1.0.0
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --install
./MiniAppBuilder --action sign --type appleId --ipa {ipaPath} --appleId xxx --password xxx --install
./MiniAppBuilder --action sign --type certificate --ipa {ipaPath} --certificatePath xxx --certificatePassword xxx --profilePath xxx --install

```

5. 到手机端打开：设置 -> 通用 -> VPN与设备管理，然后选择信任对应的签名apple账号