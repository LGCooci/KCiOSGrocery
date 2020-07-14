# README
总结iOS常见面试题，以及BAT大厂面试分享！笔者一道一道总结，如果你觉得还不错，小心心 **Star** 走一波.... Thanks♪(･ω･)ﾉ

##### 1：谈谈你对KVC的理解

`KVC`可以通过`key`直接访问对象的属性，或者给对象的属性赋值，这样可以在运行时动态的访问或修改对象的属性

当调用 **setValue：**属性值 `forKey：@”name“` 的代码时，，底层的执行机制如下：

* 1、程序优先调用`set<Key>:`属性值方法，代码通过`setter方法`完成设置。注意，这里的`<key>`是指成员变量名，首字母大小写要符合`KVC`的命名规则，下同

* 2、如果没有找到 `setName：`方法，KVC机制会检查`+ (BOOL)accessInstanceVariablesDirectly` 方法有没有返回`YES`，默认该方法会返回`YES`，如果你重写了该方法让其返回NO的话，那么在这一步`KVC`会执行`setValue：forUndefinedKey：`方法，不过一般开发者不会这么做。所以KVC机制会搜索该类里面有没有名为`<key>`的成员变量，无论该变量是在类接口处定义，还是在类实现处定义，也无论用了什么样的访问修饰符，只在存在以<key>命名的变量，KVC都可以对该成员变量赋值。

* 3、如果该类即没有`set<key>：`方法，也没有`_<key>`成员变量，KVC机制会搜索`_is<Key>`的成员变量。

* 4、和上面一样，如果该类即没有set<Key>：方法，也没有_<key>和_is<Key>成员变量，KVC机制再会继续搜索<key>和is<Key>的成员变量。再给它们赋值。

* 5、如果上面列出的方法或者成员变量都不存在，系统将会执行该对象的`setValue：forUndefinedKey：`方法，默认是抛出异常。

如果想禁用KVC，重写`+ (BOOL)accessInstanceVariablesDirectly`方法让其返回NO即可，这样的话如果KVC没有找到 `set<Key>:`
属性名时，会直接用 `setValue：forUndefinedKey：`方法。

当调用 **valueForKey：@”name“** 的代码时，KVC对key的搜索方式不同于`setValue：`属性值 `forKey：@”name“`，其搜索方式如下：

* 1、首先按`get<Key>,<key>,is<Key>`的顺序方法查找`getter`方法，找到的话会直接调用。如果是`BOOL`或者`Int`等值类型， 会将其包装成一个`NSNumber`对象

* 2、如果上面的`getter`没有找到，`KVC`则会查找`countOf<Key>,objectIn<Key>AtIndex`或`<Key>AtIndexes`格式的方法。如果`countOf<Key>`方法和另外两个方法中的一个被找到，那么就会返回一个可以响应NSArray所有方法的代理集合(它是`NSKeyValueArray`，是`NSArray`的子类)，调用这个代理集合的方法，或者说给这个代理集合发送属于`NSArray`的方法，就会以`countOf<Key>,objectIn<Key>AtIndex或<Key>AtIndexes`这几个方法组合的形式调用。还有一个可选的`get<Key>:range:`方法。所以你想重新定义KVC的一些功能，你可以添加这些方法，需要注意的是你的方法名要符合KVC的标准命名方法，包括方法签名。

* 3、如果上面的方法没有找到，那么会同时查找 `countOf<Key>，enumeratorOf<Key>,memberOf<Key>` 格式的方法。如果这三个方法都找到，那么就返回一个可以响应NSSet所的方法的代理集合，和上面一样，给这个代理集合发NSSet的消息，就会以 `countOf<Key>，enumeratorOf<Key>,memberOf<Key>` 组合的形式调用。

* 4、如果还没有找到，再检查类方法 `+ (BOOL)accessInstanceVariablesDirectly`,如果返回 `YES` (默认行为)，那么和先前的设值一样，会按 `_<key>,_is<Key>,<key>,is<Key>` 的顺序搜索成员变量名，这里不推荐这么做，因为这样直接访问实例变量破坏了封装性，使代码更脆弱。如果重写了类方法 `+ (BOOL)accessInstanceVariablesDirectly` 返回 `NO` 的话，那么会直接调用 `valueForUndefinedKey:` 方法，默认是抛出异常
