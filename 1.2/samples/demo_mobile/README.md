如何编译这个例子
========================

这个目录包含了一些源码和素材，来允许您将上一个标准项目部署到iPhone上面。

在Flash Builder中，创建一个"ActionScript移动项目"，然后添加下面的源码路径：

* 上一个项目的src目录
* iOS实例项目中的media目录。

Then exchange the source files that were created by the Flash Builder project wizard with the source files in the "src" folder of the iOS demo project. Use "Startup_iOS" as the startup class.

**Note:** You will need AIR 3.2 to deploy AIR applications on a mobile device. Furthermore, you need a developer certificate and provisioning profiles, both of which can be acquired from Apple when you are a member of the iOS Developer program. 

Known Issues:
-------------

* AIR 3.2 causes problems when you try to run/debug the app in the device simulator: you need to set "fullscreen" to "false" in the app's configuration file to see any rendering output. This is fixed in AIR 3.3.