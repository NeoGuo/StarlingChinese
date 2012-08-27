Starling框架: 基于GPU加速的2D Flash API
================================================

Starling是什么?
-----------------

Starling是一个ActionScript类库，它模仿了传统的Flash显示列表。然而，和传统的显示对象不同，Starling对象完全存在于Stage3D环境。这意味着，所有的显示对象都直接由GPU渲染，这会带来非常明显的性能提升。

Starling并不是直接1:1的复制Flash API。所有的类都针对GPU模式进行了精简和优化。Starling向开发者隐藏了Stage3D的内部细节，但如果您想创建自定义显示对象，也可以很容易访问到它们。

就像它在iOS平台的姐妹框架，[Sparrow Framework][1], Starling的设计宗旨是尽可能轻量级，易于使用。作为一个开源项目，我们非常小心，保证代码易于阅读，理解和扩展。

我从哪里可以获取Starling的最新信息?
------------------------------------------------

关于Starling的一些链接:

* [官网](http://www.starling-framework.org)
* [Starling中文站](http://www.starlinglib.com)
* [API文档](http://doc.starling-framework.org)
* [论坛支持](http://forum.starling-framework.org)
* [Starling Wiki](http://wiki.starling-framework.org)
  * [案例展示](http://wiki.starling-framework.org/games/start)
  * [书籍，课程和教程](http://wiki.starling-framework.org/tutorials/start)
  * [扩展](http://wiki.starling-framework.org/extensions/start)

[1]: http://www.sparrow-framework.org