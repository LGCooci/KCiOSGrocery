# 2020-逻辑教育iOS面试题集合

总结iOS常见面试题，以及BAT大厂面试分享！笔者一道一道总结，如果你觉得还不错，小心心 **Star** 走一波.... Thanks♪(･ω･)ﾉ

##### 1：谈谈你对KVC的理解

`KVC`可以通过`key`直接访问对象的属性，或者给对象的属性赋值，这样可以在运行时动态的访问或修改对象的属性

当调用 **setValue：**属性值 `forKey：@”name“` 的代码时，，底层的执行机制如下：

* 1、程序优先调用`set<Key>:`属性值方法，代码通过`setter方法`完成设置。注意，这里的`<key>`是指成员变量名，首字母大小写要符合`KVC`的命名规则，下同

* 2、如果没有找到 `setName：`方法，KVC机制会检查`+ (BOOL)accessInstanceVariablesDirectly` 方法有没有返回`YES`，默认该方法会返回`YES`，如果你重写了该方法让其返回NO的话，那么在这一步`KVC`会执行`setValue：forUndefinedKey：`方法，不过一般开发者不会这么做。所以KVC机制会搜索该类里面有没有名为`<key>`的成员变量，无论该变量是在类接口处定义，还是在类实现处定义，也无论用了什么样的访问修饰符，只在存在以`<key>`命名的变量，KVC都可以对该成员变量赋值。

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

##### 2：iOS项目中引用多个第三方库引发冲突的解决方法

> 可能有很多小伙伴还不太清楚，动静态库的开发，这里推荐一篇博客：[iOS-制作.a静态库SDK和使用.a静态库](https://blog.csdn.net/Feng512275/article/details/77864609)

如果我们存在三方库冲突就会保存：`duplicate symbol _OBJC_IVAR_$_xxxx in:`

**目前见效最快的就是把`.framework`选中，`taggert Membership`的对勾取消掉，就编译没有问题了，但是后续的其他问题可能还会出现**

> 我想说的是像这种开源的使用率很高的源代码本不应该包含在lib库中，就算是你要包含那也要改个名字是吧。不过没办法现在人家既然包含，我们就只有想办法分离了

* `mkdir armv7：创建临时文件夹`

* `lipo libALMovie.a -thin armv7 -output armv7/armv7.a：取出armv7平台的包`

* `ar -t armv7/armv7.a：查看库中所包含的文件列表`

* `cd armv7 && ar xv armv7.a：解压出object file（即.o后缀文件）`

* `rm ALButton.o：找到冲突的包，删除掉（此步可以多次操作）`

* `cd … && ar rcs armv7.a armv7/*.o：重新打包object file`

* 多平台的SDK的话，需要多次操作第4步。操作完成后，合并多个平台的文件为一个.a文件：`lipo -create armv7.a arm64.a -output new.a`

* 将修改好的文件， 拖拽到原文件夹下，替换原文件即可。


##### 3：GCD实现多读单写

比如在内存中维护一份数据，有多处地方可能会同时操作这块数据，怎么能保证数据安全？这道题目总结得到要满足以下三点：

* 1.读写互斥
* 2.写写互斥
* 3.读读并发

```
@implementation KCPerson
- (instancetype)init
{
    if (self = [super init]) {
       _concurrentQueue = dispatch_queue_create("com.kc_person.syncQueue", DISPATCH_QUEUE_CONCURRENT);
       _dic = [NSMutableDictionary dictionary];
    }
    return self;
}
- (void)kc_setSafeObject:(id)object forKey:(NSString *)key{
    key = [key copy];
    dispatch_barrier_async(_concurrentQueue, ^{
       [_dic setObject:object key:key];
    });
}

- (id)kc_safeObjectForKey：:(NSString *)key{
    __block NSString *temp;
    dispatch_sync(_concurrentQueue, ^{
        temp =[_dic objectForKey：key];
    });
    return temp;
}
@end
```

* 首先我们要维系一个GCD 队列，最好不用全局队列，毕竟大家都知道全局队列遇到栅栏函数是有坑点的，这里就不分析了！

* 因为考虑性能 死锁 堵塞的因素不考虑串行队列，用的是自定义的并发队列！`_concurrentQueue = dispatch_queue_create("com.kc_person.syncQueue", DISPATCH_QUEUE_CONCURRENT);`

* 首先我们来看看读操作:`kc_safeObjectForKey` 我们考虑到多线程影响是不能用异步函数的！说明：
    * 线程2 获取：`name` 线程3 获取 `age`
    * 如果因为异步并发，导致混乱 本来读的是`name` 结果读到了`age`
    * 我们允许多个任务同时进去! 但是读操作需要同步返回，所以我们选择:`同步函数` **（读读并发）**
* 我们再来看看写操作，在写操作的时候对key进行了copy, 关于此处的解释，插入一段来自参考文献的引用:

> 函数调用者可以自由传递一个`NSMutableString`的`key`，并且能够在函数返回后修改它。因此我们必须对传入的字符串使用`copy`操作以确保函数能够正确地工作。如果传入的字符串不是可变的（也就是正常的`NSString`类型），调用`copy`基本上是个空操作。

* 这里我们选择 `dispatch_barrier_async`, 为什么是栅栏函数而不是异步函数或者同步函数，下面分析：
    
    * 栅栏函数任务：之前所有的任务执行完毕，并且在它后面的任务开始之前，期间不会有其他的任务执行，这样比较好的促使 写操作一个接一个写 **（写写互斥）**，不会乱！
    
    * 为什么不是异步函数？应该很容易分析，毕竟会产生混乱！
   
    * 为什么不用同步函数？如果读写都操作了，那么用同步函数，就有可能存在：我写需要等待读操作回来才能执行，显然这里是不合理！

##### 4:讲一下atomic的实现机制；为什么不能保证绝对的线程安全（最好可以结合场景来说）？

**A: atomic的实现机制**
* `atomic`是`property`的修饰词之一，表示是原子性的，使用方式为`@property(atomic)int age`;此时编译器会自动生成 `getter/setter` 方法，最终会调用`objc_getProperty`和`objc_setProperty`方法来进行存取属性。

* 若此时属性用`atomic`修饰的话，在这两个方法内部使用`os_unfair_lock` 来进行加锁，来保证读写的原子性。锁都在`PropertyLocks` 中保存着（在iOS平台会初始化8个，mac平台64个），在用之前，会把锁都初始化好，在需要用到时，用对象的地址加上成员变量的偏移量为`key`，去`PropertyLocks`中去取。因此存取时用的是同一个锁，所以atomic能保证属性的存取时是线程安全的。

* 注：由于锁是有限的，不用对象，不同属性的读取用的也可能是同一个锁

**B: atomic为什么不能保证绝对的线程安全？**

* `atomic`在`getter/setter`方法中加锁，仅保证了存取时的线程安全，假设我们的属性是`@property(atomic)NSMutableArray *array`;可变的容器时,无法保证对容器的修改是线程安全的.

* 在编译器自动生产的`getter/setter`方法，最终会调用`objc_getProperty`和`objc_setProperty`方法存取属性，在此方法内部保证了读写时的线程安全的，当我们重写`getter/setter`方法时，就只能依靠自己在`getter/setter`中保证线程安全



##### 5. Autoreleasepool所使用的数据结构是什么？AutoreleasePoolPage结构体了解么？

* `Autoreleasepool`是由多个`AutoreleasePoolPage`以双向链表的形式连接起来的.

* `Autoreleasepool`的基本原理：在每个自动释放池创建的时候，会在当前的`AutoreleasePoolPage`中设置一个标记位，在此期间，当有对象调用`autorelsease`时，会把对象添加 `AutoreleasePoolPage`中

* 若当前页添加满了，会初始化一个新页，然后用双向量表链接起来，并把新初始化的这一页设置为`hotPage`,当自动释放池pop时，从最下面依次往上pop，调用每个对象的`release`方法，直到遇到标志位。

**`AutoreleasePoolPage`结构如下**
```
class AutoreleasePoolPage {
    magic_t const magic;
    id *next;//下一个存放autorelease对象的地址
    pthread_t const thread; //AutoreleasePoolPage 所在的线程
    AutoreleasePoolPage * const parent;//父节点
    AutoreleasePoolPage *child;//子节点
    uint32_t const depth;//深度,也可以理解为当前page在链表中的位置
    uint32_t hiwat;
}
```


##### 6: iOS中内省的几个方法？class方法和objc_getClass方法有什么区别?

* 1: 什么是内省？

> 在计算机科学中，内省是指计算机程序在运行时（Run time）检查对象（Object）类型的一种能力，通常也可以称作运行时类型检查。
不应该将内省和反射混淆。相对于内省，反射更进一步，是指计算机程序在运行时（Run time）可以访问、检测和修改它本身状态或行为的一种能力。

* 2：iOS中内省的几个方法？

`isMemberOfClass` //对象是否是某个类型的对象
`isKindOfClass` //对象是否是某个类型或某个类型子类的对象
`isSubclassOfClass` //某个类对象是否是另一个类型的子类
`isAncestorOfObject` //某个类对象是否是另一个类型的父类
`respondsToSelector` //是否能响应某个方法
`conformsToProtocol` //是否遵循某个协议

* 3: `class`方法和`object_getClass`方法有什么区别?
    
    * 实例`class`方法就直接返回`object_getClass(self)`
   
    * 类`class`方法直接返回`self`，而`object_getClass`(类对象)，则返回的是元类
