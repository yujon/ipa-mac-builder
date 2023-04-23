## 描叙
本工具用于在mac系统上ipa 用个人免费证书重签名并安装到手机上。
### 使用步骤

1. 需要安装一个 Mail 插件，步骤如下：

- 下载 [MiniAppPlugin](https://dldir1.qq.com/WechatWebDev/donut/download/MiniAppPlugin.zip) 插件, 解压后将`MiniAppPlugin.mailbundle`放到`/Library/Mail/Bundles`目录下

- 打开`Mail`，到 菜单 邮件 -> 设置 -> 管理插件, 启动`MiniAppPlugin.mailbundle`插件，然后重启`Mail`

2. 下载MiniAppBuilder并解压

3. 将`iphone`手机用数据线连接到电脑上

4. 然后打开终端工具，执行以下命令，该命令将会从ipa重签名并安装到手机上

```sh
cd MiniappMacBuilder-v1.0.0
./MiniAppBuilder  {ipaPath}  {your apple account} {your apple password}
# ./MiniAppBuilder /a/b/demo.ipa xxx xxx

```

5. 到手机端打开：设置 -> 通用 -> VPN与设备管理，然后选择信任对应的签名apple账号