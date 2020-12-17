# minio

> 基于flutter实现的minio客户端
### 一些信息

- 使用的flutter sdk为1.22.5版本
- 实现了绝大多数web端有的功能，但非常的遗憾是无法完成上传功能，等到官方sdk出现可能会去重新实现 [web端公共体验地址](https://play.min.io/minio/)
- 采用rxdart做状态管理 (因为之前有使用过rxjs所以)
- 项目有借鉴其他源码，也有之前copy修改。
- 此项目是练手项目，但个人认为如果只需要用到下载的功能此项目还是挺实用的

### 开端

我是很久之前阅读过[此书籍]("https://book.flutterchina.club/")，也只看到滚动widget那块。最近突然想学习一些其他东西。刚好之前曾经用react-native试着写个app的minio客户端。但官方的[sdk](https://docs.minio.io/cn/javascript-client-quickstart-guide.html)无法在react-native运行，采用其他方案但不理想后面就放弃了。所以现在就打算用flutter实现minio客户端。

### 总结

我并没有完整的看过flutter和dart的文档，是边写边学，遇见了问题就百度谷歌查询的。flutter的widget相当于前端的组件写页面还是比较简单，但widget实在太多了，并不知道哪个场景下上面widget是最实用的。

并且我觉得flutter项目要想写好，还得有原生的基础才能更容易理解flutter，一些常用的底层都是android和ios实现的。并且在写项目时有权限配置等问题都是原生的配置，有点难理解，不懂如何配置。