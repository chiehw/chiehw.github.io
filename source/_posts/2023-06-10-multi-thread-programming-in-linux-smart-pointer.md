---
title: 《Linux 多线程服务端编程》-1 智能指针
categories: 编程杂货铺
tags:
  - C++
  - 多线程
  - 《Linux 多线程服务端编程》
abbrlink: c5e38125
date: 2023-06-10 10:06:10
---

# 第1章：线程安全的对象生命周期管理

## 01 如何避免对象析构时可能存在的竞争条件？

当一个对象能被多个线程同时看到时，那么对象的销毁时机就会变得模糊不清，可能存在多种竞争状态：

1. 在即将析构一个对象时，从何而知此刻是否有别的线程正在执行该对象的成员函数？
2. 如何保证在执行成员函数期间，对象不会在另一个线程被析构？（类似上一个问题）
3. 在调用某个对象的成员函数之前，如何得知这个对象是否还活着？它的析构函数是否碰巧执行到一半？

可以借助 Boost 库中的 **shared_ptr 和 weak_ptr** 完美解决，这也是实现线程安全的 Observer 模式的必备计数。

## 02 什么是 Observer 模式？

Observer 模式也就是我们常说的观察者模式，观察者模式是软件设计模式中的一种，在此模式中，一个目标对象管理所有相依于它的观察者对象，并且在它本身的状态改变时发出通知。

这通常透过调用各观察者所提供的方法来实现，此种模式通常被用在即时事件处理系统。

## 03 C++ 在函数末尾添加 const 有什么用？

在函数声明的末尾添加 const 关键字，被称为常量成员函数。它表示该函数不会修改对象的状态，即它不会修改任何非静态成员变量。常量成员函数可以提高代码的可读性和安全性，因为它们不会修改成员的对象，这有助于避免意外的副作用和错误。

## 04 mutable 有什么用？

mutable 关键字用于在常量成员函数中修改对象的可变状态。在 C++ 中，常量成员函数不能修改对象的非 mutable 成员变量，因为这回违反常量成员函数的语义。

但在多线程编程中，通常需要使用互斥量（mutex）来保护共享资源。在类中，通常互斥量作为一个成员变量来实现多线程同步，常量成员函数则不能在其中修改互斥量的状态。

为了解决这个问题，可以使用 mutable 关键字来标记互斥量，以便在常量成员函数中修改互斥量的状态。

## 05 如下代码所示，如果 mutex_ 是 static，是否会影响正确性或性能？

```c++
class Counter{
    private:
    	mutable MutexLock mutex_;
}
```

如果 mutex_ 是 static 修饰，那么所有 counter 共享一个 mutex_ 变量，运行时会同时争抢一个锁，不会影响正确性，但会严重影响性能，尤其是同时存在多个 counter 对象时。

## 06 MutexLock 和 MutexLockGuard 如何搭配使用？

MutexLock 用于声明 Mutex 对象 `mutex_`，用于存储锁相关的信息。MutexLock 通常是类的数据成员，并且被 mutable 所修饰。MutexLock 封装临界区，它是一个简单的资源类，用 RAII 手法封装互斥器的创建和销毁。临界区在 Windows 上是 struct CRITICAL_SECTION，是可重入的；在 Linux 下是 pthread_mutex_t，默认是不可重入的。

MutexLockGuard 则利用 `mutex_`  来加锁和解锁。而 MutexLockGuard 是栈上的对象，需要使用 MutexLock 来初始化，它的作用域刚好等于临界区域。

```c++
class Counter{
    public:
    	int64_t value() const;
    private:
    	int64_t value_;
    	mutable MutexLock mutex_;
}

int64_t Counter::value() const{
    MutexLockGuard lock(mutex_);
    return value_
}
```

## 07 在对象构造时，如何保证线程安全？

对象构造要做到线程安全，唯一的要求是在构造期间不要泄露 this 指针，即：

1. 不要在构造函数中注册任何回调（不要把对象的 this 指针传递给任何对象）。
2. 即便在构造函数的最后一行也不行（构造函数完成之后，C++ 可能还需要做一些其他的操作）

构造函数在执行期间对象还没有完全初始化，如果将 this 泄露（escape 给了其他对象），那么别的线程有可能访问这个半成品对象，这会造成难以预料的后果。**即时构造函数的最后一行也不要泄露 this**。 因为该类可能是基类，基类先于派生类构造，执行完基类的构造函数还会继续执行派生类的构造函数。这时大部分的派生类还处于构造中，依然不安全。

**二段式构造——即构造函数+initialize() 有时会是好办法**。这虽然不符合 C++ 教条，但在多线程下别无选择。二段式构造还能简化错误处理，靠 initialize 的返回值来判断对象是否构造成功。

## 08 为什么 mutex 无法保护析构？

当进入析构函数时，给 mutex 加锁，让其他函数阻塞。虽然其他函数阻塞了，但当析构函数结束时，该对象便会被销毁。持有持有该锁的线程将不再被阻塞，并且它将继续执行。无法预估后续函数会如何执行。

析构过程也不需要保护，只有别的线程都无法访问这个对象的时候，析构才是安全的。

## 09 如何锁住多个对象？

```c++
void swap(Counter &a, Counter &b){
    MutexLockGuard aLock(a.mutex_);
    MutexLockGuard bLock(b.mutex_);
}
```

如果线程 A 执行 swap(a, b)，而同时线程 B 执行 swap(b, a)，就有可能发生死锁。

一个函数如果要锁住相同类型的多个对象，为了保证始终按照相同的顺序加锁，我们可以**比较 mutex 对象的地址，始终先加锁较小的 mutex。**

## 10 判断对象是否被销毁的难点在哪？如何解决？

一个动态创建的对象是否还活着，光看指针是看不出来的（malloc 创建）。指针就是指向了一块内存，这块内存上的对象如果已经销毁，那么就根本不能访问，既然不能访问又如何知道对象的状态呢？

换句话说，判断一个指针是不是合法指针有没有高效方法，这是 C/C++ 指针的根源（万一原址又创建了一个新的对象呢？再万一这个新的对象的类型异于老的对象呢？。

1. 无法判断是否有对象。
2. 无法判断对象是不是老对象（并非析构后又创建的）

解决方案就是“**智能指针**”。

## 11 面向对象程序设计中，对象有哪些关系?

对象之间的关系可以分为三种：组合（composition）、聚合（aggregation）和关联（association）。它们的区别如下：

- 组合（composition）：表示一种“整体-部分”的关系，即一个对象由多个其他对象组成，这些对象的生命周期是相互依赖的，如果主对象被销毁，那么其他对象也会被销毁。通常用实心菱形表示，例如，一个汽车由引擎、轮胎、座椅等部分组成。
- 聚合（aggregation）：也表示一种“整体-部分”的关系，但部分对象的生命周期不依赖于主对象。使用空心菱形表示，例如，一个学校由多个班级组成，班级可以独立。
- 关联（association）：表示两个对象的关系，它们可以相互引用，但是彼此之间的生命周期不依赖于对方。使用普通箭头表示，例如，一个人可以有一辆汽车。

## 12 什么是悬空指针？

有两个指针 p1 和 p2，指向堆上同一个对象 Object，p1 和 p2 位于不同的线程中。

![image-20230429134015168](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/04/upgit_20230429_1682746815.png)

假设线程 A 通过 p1 指针将对象销毁了，并且把 p1 置为 null，那 p2 就成了悬空指针。

![image-20230429134228162](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/04/upgit_20230429_1682746948.png)

## 13 垃圾回收的核心原理是什么？

想要安全的销毁对象，最好在别人（线程）都看不到的情况下，偷偷的做。所有人都用不到的东西一定是垃圾。

## 14 如何避免悬空指针？

计数型智能指针。其核心原理包含两个关键点，一是引入间接性，而是利用计数来安全释放间接层的智能指针。

**引入间接性，增加 proxy 对象**。这样能让 p1 和 p2 所指向的对象永久有效，当销毁 Object 之后，proxy 对象继续存在，其值变为 0，p2 也不会变成空悬指针，它可以通过查看 proxy 的内容来判断 Object 是否还活着。

![image-20230429135342912](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/04/upgit_20230429_1682747623.png)

**计数判断释放时机**。为 proxy 增加计数，没有任何东西指向 proxy，那这个 proxy 就可以被销毁了，在销毁 proxy 的时候再销毁 Obejct。如果 proxy 的计数大于等于 1 就不能销毁 Object。

![image-20230429140028041](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/04/upgit_20230429_1682748028.png)

## 15 shared_ptr 和 weak_ptr 的区别和联系？

shared_ptr 和 weak_ptr 都是引用计数型指针，当引用计数降到 0 时，对象即被销毁。

- shared_ptr  控制对象的生命周期。shared_ptr 是强引用，只要有一个指向 x 对象的 shared_ptr 存在，该 x 对象就不会析构。当指向对象 x 的最后一个 shared_ptr 析构的时候，x 保证会被销毁。
- weak_ptr 不控制对象的生命周期，但是他知道对象是否还活着，并且 也不会增加对象的引用次数。如果对象还存在，那么它可以提升为有效的 shared_ptr，如果对象已经死了，提升会失败，返回一个空的 shared_ptr。

## 16 C++ 有可能出现哪些内存问题？如何解决？

- 缓冲区溢出：用 vector 或 string，自动记住缓冲区的长度，并通过成员函数而不是裸指针来修改缓冲区。
- 悬空指针/野指针：用 shared_ptr/weak_ptr。
- 重复释放：用 scoped_ptr，只在对象析构的时候释放一次。
- 内存泄漏：用 scoped_ptr，对象析构的时候自动释放内存。
- 不配对的 new 和 delete：把 new[] 通通替换成 vector。
- 内存碎片：以后再谈论。

## 17 为什么不可重入的 mutex 更优？

Go 的 mutex 就不支持可重入，官方给出了相关的案例：

```go
func F() {
        mu.Lock()
        ... do some stuff ...
        G()
        ... do some more stuff ...
        mu.Unlock()
}

func G() {
        mu.Lock()
        ... do some stuff ...
        mu.Unlock()
}
```

在上述代码中，我们在 F 方法中调用 mu.lock 方法加上锁。如果支持可重入锁，接着就会进入 G 方法。此时就有一个致命的问题，你不知道 F 和 G 方法加锁之后是不是做了相同的事情，从而破坏了不变量，也**违背了 mutex 的设计理念**。

不可重入的 mutex 可以把程序的逻辑错误暴露出来，死锁很容易 debug，，把各个线程的调用栈打出来即可。

## 18 什么是线程安全？

多个线程同时访问时，其表现出正确的行为。

## 19 shared_ptr 是不是线程安全？

我们可以借助 shared_ptr 来实现线程安全的对象的析构，但是 shared_ptr 本身不是 100% 线程安全的。它的引用计数本身是安全且无锁的，但是对象的读写不是。

如果要从多个线程读写一个 shared_ptr 对象，那么需要加锁，也就是使用 mutex 保护。

## 20 为什么对象的创建要在临界区之外？

```c++
void write(){
    shared_ptr<Foo> newPtr(new Foo);
    {
        MutexLockGuard lock(mutex);
        globalPtr = newPtr
    }
}
```

在临界区之外执行 new Foo，通常比 globalPtr.reset(new Foo) 更好，因为缩短了临界区间，在并发的时候能较小锁的时间。

## 21 Observers 如果使用 shared_ptr，而不是 weak_ptr 会有什么后果？

会意外的延长对象的生命周期。

shared_ptr 是强引用，只要有一个指向 x 对象的 shared_ptr 存在，该对象就不会析构。除非手动调用 unregister()，否则 Observer 对象永远不会析构。

## 22 const 引用有什么好处？

shared_ptr 的拷贝开销比拷贝原始指针要高，多数情况我们可以使用 const reference 的方式传递，减少拷贝次数。

使用 const 引用还有以下好处：

1. **避免不必要的复制**：使用 const 引用可以避免不必要的复制，因为它不会创建副本。
2. **避免意外修改**：使用 const 引用可以避免意外的修改，因为它不允许对引用的值进行修改。
3. **更好的代码可读性**：使用 const 引用可以提高代码可读性，因为它表面这个引用不可修改。

## 23 C++ 最重要的特性是什么？

我认为 RAII（资源获取即初始化）是 C++ 语言区别于其他所有编程语言的最重要的特性，一个不懂 RAII 的 C++ 程序员不是一个合格的 C++ 程序员。

初学 C++ 的教条是 “new 和 delete 要配对，new 了之后要记得 delete”。如果使用 RAII，**要改成每个明确的资源配置动作都应该在一条语句中执行，并在该语句中立即将配置获得的资源交给 handle 对象（如 shared_ptr），程序中一般不出现 delete。**

shared_ptr 是资源共享的利器，需要注意避免循环引用，通常的做法是 **owner 持有 child 的 shared_ptr，child 持有 owner 的 weak_ptr**。

## 24 unique_ptr 和 shared_ptr 的区别？

有以下两个关键的区别：

1. 所有权：unique_ptr 只能拥有一个所有权，即不能被多个指针所共享（因此禁止拷贝和赋值操作），而 shared_ptr 可以被多个指针共享所有权。
2. 性能：unique_ptr 通常比 shared_ptr 更轻量。

## 25 什么是 work around？

work around 通常是在遇到无法解决的问题时采取的一种权宜之计，它可能不是最优的解决方案，但可以在一定程度缓解问题带来的影响。work around 可以是一段代码，一组配置或一种操作，通常是为了解决某个特定问题而设计的。

## 26 Observer 在面向对象中有哪些难点？如何解决？

Observer 模式的本质问题在于其面向对象的设计。换句话说，我认为正是面向对象（OO）本身造成了 Observer 的缺点。

Observer 是基类，这带来了非常强的耦合，强度仅次于友元（Friend）。这种耦合不仅限制了成员函数的名字、参数、返回值，还限制了成员函数所属的类型（必须是 Observer 的派生类）。Observer class 是基类，这意味着如果 Foo 想要观察两个类型的事件（温度和时钟），需要使用多继承。这还不是最糟糕的，如果要重复观察同一个类型的事件（比如 1 秒 1 次的心跳和 30 秒一次的自检），就要用一些伎俩来 work around。

在 C++ 里为了替换 Observer，可以使用 Signal/Slots（标准库中的 Sinal/Slots），并且不强制要求 shared_ptr 来管理对象。例如：varidic template。

## 27 如何设计 StockFactory 类？

假设 Stock 类，代表一只股票的价格（唯一性，商品的价格也可以用这个设计）。每一只股票有一个唯一的字符串表示。

为了节省系统资源，同一个程序里面每一只出现的股票只能有一个 Stock 对象，如果多处用到同一支股票，那么 Stock 对象应该被共享。如果某一只股票没有在其他任何地方用到，其对应的 Stock 应该被析构，以释放资源，这隐含了“引用计数”。

![image-20230501134923037](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/05/upgit_20230501_1682920163.png)

为了达到上述要求，我们可以设计一个对象池 StockFactory。它的接口很简单，根据 key 返回 Stock 对象。

## 28 noncopyable 有什么用？

noncopyable 是一个 C++ 类模板，用于禁止一个类被拷贝构造或拷贝赋值。noncopyable 类模板通常作为一个基类，用于防止派生类被拷贝。

在 C++ 中，如果一个类没有 定义拷贝函数和拷贝构造函数，编译器会自动生成默认的拷贝构造函数和拷贝赋值运算符。这些默认函数会对对象的成员逐个拷贝到新的对象中，这可能会导致一些问题，例如浅拷贝问题或多个对象共享同一块内存等。

## 29 为什么要定制 shared_ptr/weak_ptr 的析构功能？

shared_ptr/weak_ptr 可以用于工厂类，工厂类内部会使用 map 来存储产生的对象。当类的引用为 0 时（shared_ptr），对象实例会自动销毁，但在 map 中的 weak_ptr 包裹的类却一直存在。

定制析构函数之后，可以在引用为 0 时，做自定义的操作（如：在 map 删掉已经被销毁的对象）。

## 30 如何定制 shared_ptr 的析构功能？

shared_ptr 的构造函数可以有一个额外的模板类型参数，**传入一个函数指针或仿函数 d，在析构对象时执行 d(ptr)**，其中 ptr 时 shared_ptr 保存的对象指针。

```c++
template<class Y, class D> shared_ptr( Y * p, D d ): px( p ), pn( p, d )
{
    boost::detail::sp_deleter_construct( this, p );
}
template<class Y, class D> void reset( Y * p, D d )
{
    this_type( p, d ).swap( *this );
}
```

也就是说，我们可以在 share_ptr 初始化时创建定制析构功能，也可以在 reset 函数这。

```c++
// StockFactory::get 
shared_ptr<Stock> pStock;

MutexLockGuard lock(mutex_);
weak_ptr<Stock> &wStock = stocks_[key];
pStock = wStock.lock();
if (!pStock)
{
    pStock.reset(new Stock(key), boost::bind(&StockFactory::deleteStock, this, _1)); // warning: 这里直接传入了 this 指针，Stock 对象无法确定 StockFacotory 对象是否还存活
    wStock = pStock; // update wStock
}
```

## 31 boost::bind 有什么用？

boost::bind 是一个函数对象适配器，它允许我们将一个成员函数或一个非成员函数绑定到特定的对象，并创建一个新的函数对象。这个新的函数对象可以像一个普通函数一样调用，但会自动将绑定的对象作为第一个参数传递。

可以将 boost::bind 创建的函数对象理解为一种闭包（closure），因为它可以捕获其绑定的对象，并在需要时作为参数传递给函数。

## 32 如何获得指向当前对象的 shared_ptr 对象呢？

使用 enable_shared_from_this，这是一个以其派生类为模板类型实参的基类模板的基类模板，继承它，this 指针就能变身为 shared_ptr。

shared_from_this() 函数的调用不能是 stack object，必须是 heap object 且由 shared_ptr 管理其生命周期。还需要注意一点，shared_from_this() 不能在构造函数里调用，因为在构造 StockFactory 的时候，它还没有交给 shared_ptr 接管。

使用 `boost::bind(deleteStock, shared_from_this)` 时，boost::function 里会保存一份 shared_ptr 指针，可以延长对象的的生命周期。

## 33 什么叫弱回调？

如果对象还活着，就调用它的成员函数，否则忽略之。弱回调主要是利用 weak_ptr 来探测对象是否存活。weak_ptr 也可以绑到  boost::funcion 中：

```c++
pStock.reset(
    new Stock(key), 
    boost::bind(&StockFactory::weakDeleteCallback, boost::weak_ptr<StockFactory>(shared_from_this()), 
    _1));
```

