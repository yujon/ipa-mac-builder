### 使用步骤

1. 需要安装一个 Mail 插件，步骤如下：

- 下载 [MiniAppPlugin](http://dldir1.qq.com/WechatWebDev/donut/download/MiniAppPlugin.zip) 插件, 解压后将`MiniAppPlugin.mailbundle`放到`/Library/Mail/Bundles`目录下

- 打开`Mail`，到 菜单 邮件 -> 设置 -> 管理插件, 启动`MiniAppPlugin.mailbundle`插件，然后重启`Mail`

2. 打包终端，执行命令:

```sh
./MiniAppBuilder  {ipaPath}  {your apple account} {your apple password}
# ./MiniAppBuilder ./demo.ipa  xxx xxx
```