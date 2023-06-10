---
title: 《Effective C++》-1 面向对象
date: 2023-06-10 10:01:25
categories: 程序人生
tags:
- C++
- 《Effective C++》
---

# 前言

# 条款1：视 C++ 为一个语言联邦

## 01 如何理解 C++？

最简单的方法就是将 C++ 视为一个相关语言的联邦，而非单一语言。C++ 一共有四个次语言：

1. C：C++ 是以 C 为基础，许多时候 C++ 对问题的解法其实不过就是较高的 C 解法。
2. Object-Oriented C++：C++ 的面向对象编程。
3. Template C++：由于 templates 威力强大，它们带来崭新的编程范型，也就是所谓的 template metaprogramming（TMP，模板元编程）。
4. STL：STL 是一个 template 程序库，但它是非常特殊的一个。

# 条款2：尽量以 const，enum，inline 替换#define

## 01 为什么要避免使用预处理器？

减少预处理器的使用，更容易获取正确的编译错误信息。语句 `#define ASPECT_RATIO 1.653` 中的 `ASPECT_RATIO` 也许从未被编译器看到，因为在编译器处理源码之前已经被预处理器移走了。

更好的解决办法是使用 const, enum, inline 替换 #define，他们能大大降低我们对 #define 的需求。

- 对于单纯的常量，最好使用 const 对象或 enums 替换 #defines。
- 对于形似函数的宏，最好改用 inline 函数替换 #defines。

```c++
const double AspectRadio = 1.653;
```

## 02 如何定义常量指针 constant pointers？

假如要在头文件内定义一个常量的 char*-based 字符串，必须写两次 const；

```c++
char greeting[] = "Hello";
const char* const p = greeting;// const pointer, const data
```

如果关键字 const 出现在星号左边，表示被指物是常量；如果出现在星号右边，表示指针自身是常量；如果出现在星号左右两边，表示被指物和指针两者都是常量。

```c++
char greeting[] = "Hello";
char* p = greeting; // non-const pointer, non-const data
const char* p=greeting; // non-const pointer, const data
char* const p = greeting; // const pointer, non-const data
const char* const p = greeting; // const pointer, const data
```

## 03 如何初始化类中的 static 成员？

在 C++ 中，类中的静态成员变量必须在类外进行定义和初始化，因为静态成员变量是属于整个类，而不是属于类的任何一个对象。

```c++
class CostEstimate {
    private:
    	static const double FudgeFactor;	// static class 常量声明
    .	..	
}
const double ConstEstimate::FudgeFactor = 1.35;
```

# 条款03：尽可能使用 const

## 01 const 迭代器是什么意思？

迭代器的作用就像指针。声明迭代器为 const 就像声明指针为 const 一样（即声明一个 T* const 指针），表明这个迭代器不得指向不同的东西，但是它所指的东西的值是可以改变的。

如果你希望迭代器所指的东西不可改动（即希望 STL 模拟一个 const *T 指针），你需要的是 const_iterator。

## 02 令函数返回常量值有什么用？

可以降低因客户错误而造成的意外，而又不至于放弃安全性和高效性。如 `const Rational operator*()` ，这里的 const 就可以避免用户写出下面这种错误的语句：

```c++
if (a*b = c)
```

避免人们把 == 写成 =。

## 03  const 成员函数有什么优点？

1. 使得 class 接口更利于理解。这是因为，得知哪个函数可以改动对象而哪个函数不行，很是重要。
2. 使操作 “const” 对象成为可能。mutable 只能用来修饰类的数据成员，这些数据成员可以在 const 成员函数中修改。

## 04 返回值为 char& 和 char 的区别？

operator[] 通常返回 char&。

如果 operator[] 只是返回一个 char，下面这样的句子就无法通过编译：

```c++
tb[0] = 'x';
```

如果函数的返回值是个内置类型，那么改动函数的返回值就不合法（不符合设计理念）。纵使合法，C++ 以 by value 返回对象意味着被改动的其实是 tb.text[0] 的副本，而不是 tb.text[0] 本身。

## 05 `char& opt[](size_t pos) const}`的 const 作用？

const 关键字可以用于成员函数声明，表示该成员函数不会修改对象的状态。在这个特定的函数声明中，const 关键字表示该函数时一个**常量成员函数**。即它不会修改对象的状态，并且在常量对象上被调用（重载）。这种 const 函数可以修改 mutable 数据成员。

## 06 什么是转型？

non-const 和 const 的代码重复时（返回值不同时），可以利用 casting 来减少代码重复。

在 p24 也中，const operator[] 完全做掉了 non-const 版本该做的一切，唯一的不同就是其返回值是其类型多了一个 const 资格修饰。这种情况下如果将返回值的 const 转除是安全的，因为无论谁调用 non const operator[] 都一定首先有个 non-const 对象，否则就不能调用 non-const 函数。

```c++
char& operator[](std::size_t position)
{
    return const_cast<char&>(	// const -> non-const
    	static_cast<const TextBlock&>(*this)[position]		// non-const -> const
    );
}
```

## 07 为什么不用令 const 函数调用 non-const 函数避免重复代码？

const 成员函数承诺不改变其对象的逻辑状态，non-const 却没有这样的承诺。如果在 const 函数内调用 non-const，会打破原来承诺的不改动对象。

# 条款04：确定对象被使用前已先被初始化

## 01 初始化和赋值的区别？

在构造函数中，通常会有初始化和赋值两种操作。初始化的时间更早，通常是在成员初值列完成。构造函数内部通常都是赋值操作。

## 02 C++成员初始化的次序是怎样的？

C++ 有着十分固定的“成员初始化次序”，**base classes 更早于其 derived classes 被初始化，而 class 的成员变量总是其声明次序被初始化**。为了避免你的检阅者迷惑，并避免某次可能存在的晦涩错误，**当你在成员初值列中条列成员是，最好总是以其声明次序为次序**。

## 03 编译单元是什么？

编译单元（translation unit）是指产出单一目标文件（single object file）的那些源码。基本上它是单一源码文件加上其所含入的头文件（#include files）。

## 04 local static 对象是什么？

static 对象，其寿命从被构造出来直到程序结束为止，因此 stack 和 heap-based 对象都被排除。这种对象包括 global 对象、定义于 namespace 作用域内的对象、在 class 内、在函数内、以及在 file 作用域内被声明为 static 的对象。

函数内的 static 对象称为 local static 对象（因为它们对于函数而言是 local），其他 static 对象称为 non-local static 对象。程序结束时 static 对象会被销毁，也就是它们的析构函数会在 main 结束时被自动调用。

## 05 跨编译单元，如何保证初始化次序？

问题描述：不同编译单元内，某个编译单元内的 non-local static 对象的初始化动作使用了另一个编译单元内的某个 non-local static 对象，它所用到的这个对象可能尚未被初始化，因为 C++ 对定义于不同的编译单元内的 non-local static 对象 的初始化次序并无明确定义。

解决：将每个 non-local static 对象搬到自己专属的函数内（该对象在此函数内被声明为 static）。这些函数返回一个 reference 指向它所包含的对象。然后用户调用这些函数，而不是直接指涉这些对象。

换句话说，使用 local static 对象替换 non-local static 对象（**Singleton 模式的常见实现手法，在 LevelDB 中的 Env 就运用了这一手法**）。

# 条款05：了解 C++ 默认编写并调用哪些函数

## 01  copy assignment 函数如何工作？

copy assignment 的工作原理是将右侧操作数的值赋给左侧操作数。这通常涉及到堆上分配内存、将数据从一个对象复制到另一个对象、释放旧内存。

需要注意的是，再实现赋值运算符时，需要小心地处理自我赋值的情况，以避免出现不必要的内存分配和数据损坏。

## 02 copy assignment 函数如何处理自我赋值？

```c++
inline String &String::oprator=(const String& str){
    if(this = &str)
        return *this;
    delete[] m_data;
    m_data = new char[strlen(str.m_data) + 1];
    strcpy(m_data, str.m_data);
    return *this;
}
```

拷贝赋值需要先清理对象原本的内容，该归还的内存要归还，该释放的设备句柄要释放。在赋值时需要注意自我赋值的检查，一来提高效率，二来避免自我赋值时出现内存错误。

## 03 拷贝构造和拷贝赋值的区别？

拷贝构造是原本没有对象，在一块新的内存上以另一个对象为模板创建对象的过程。拷贝构造只需要复制就行了，不用操心别的。

拷贝赋值是原本已经有过一个对象，在这个对象所占据的内存中，以另一个对象重新设置内容的过程。拷贝赋值需要先清理对象原本的内容，该归还的内存要归还，该释放的设备句柄要释放。

拷贝构造和拷贝赋值的主要区别是：**拷贝构造函数用于创建新对象，而拷贝赋值运算符用于修改已经存在的对象**。

## 04 C++编译器会自动编写哪些函数？

编译器可以暗自为 class 创建 default 构造函数、**copy 构造函数、copy assignment 操作符**，以及析构函数。

不过，在生成 copy 和 copy assignment 时，只有生成的代码合法并且有适当机会证明它有意义，才会自动 derive 这些函数。如：

- 如果你打算在一个“**内含 reference 成员**”的 class 内支持赋值操作，你必须自己定义 copy assignment 操作符，面对**内含 const 成员**的 class 也一样。
- 如果某个 base classes 将 copy assignment 操作符设置为 private，编译器拒绝为其 derived classes 生成 copy assignment。

# 条款06：若不想使用编译器自动生成的函数，就该明确拒绝

## 01 如何阻止编译器自动生成函数？

**可以将相应的成员函数声明为 private 并且不予实现，还可以使用 Uncopyable 这样的 base class。**

```c++
class HomeForSale {
    public:
    	...
    private:
    	...
        HomeForSale(const HomeForSale&);
    	HomeForSale& operator=(const HomeForSale&);
}
```

参数名称也并不是必要的，只不过大家总是习惯写出来。有了上述 class 定义，当客户企图拷贝 HomeForSale，编译器会阻挠他。如果你不慎在 member 函数或 friend 函数之类这么做，连接器也会阻挠他。

“将成员函数声明为 private 并且故意不实现”这一伎俩是被大家所接受的，在 C++ 的 iostream 库中 io_base、basic_ios 的 copy 构造函数和 copy assignment 都是被声明为 private。

# 条款7：为多态基类声明 virtual 析构函数

## 01 用 base class 指针删除 derived 类有什么问题？如何解决？

C++ 明确指出，当 derive class 对象经由一个 base class 指针被删除，而该 base class 带着一个 non-virtual 析构函数，当实际执行时通常发生的是**对象的 derived 成分没被销毁**。

**给 base class 定义 virtual 析构函数**。此后删除 derived class 就会如同你想要的那样。它会销毁整个对象，包括 derived class 部分。

## 02 virtual 函数的作用是什么？

virtual 函数的目的是**允许 derive class 的实现得以客制化**。例如 TimeKeeper 就可能拥有一个 virtual getCurrentTime，它在不同的 derived class 中有不同的实现。

任何 class 只要带有 virtual 函数都几乎确定应该也有一个 virtual 析构函数。如果 class 不含有 virtual 函数，通常表示它并不意图被用作一个 base class。当 class 不企图被当作 base class，令其析构函数为 virtual 往往是一个馊主意。

polymorphic（带多态性质的）base clases 应该声明一个 virtual 析构函数。如果 class 带有任何 virtual 函数，它就应该拥有一个 virtual 析构函数。

## 03 virtual 函数的实现方式？

想要实现 virtual 函数，对象必须携带某些信息，主要用来在运行期决定哪个 virtual 函数应该被调用。这份信息通常是由 vptr（virtual table pointer）指针指出。

vptr 指向一个函数指针构成的数组，称为 vtbl（virtual table），每一个带有 virtual 函数的 class 都有一个相应的 vtbl。当对象调用某一 virtual 函数，实际被调用的函数取决于该对象的 vptr 所指的那个 vtbl——编译器在其中寻找适当的函数指针。

## 04 virtual 函数的缺点？

virtual 函数会增加对象的体积，可能导致 C++ 对象无法和 C 语言有相同的结构，也就是说不能把它传递至其他语言编写呃呃的函数，除非你补偿 vptr。

许多人的心得是：只有当 class 内含至少一个 virtual 函数，才为它声明 virtual 析构函数。Classes 的设计目的如果不是作为 base classes 使用，或不是为了具备多态性，就不该声明 virtual 析构函数。

## 05 base classes 和多态的联系？

并非所有的 base classes 的设计目的都是为了多态，例如标准 string 和 STL 容器都不被设计作为 base classes 使用，更别提多态了。某些 class 的设计目的是作为 base classes 使用，而不是为了多态用途（如 Uncopyable）。

Classes 的设计目的如果不是作为 base classes 使用，或不是为了具备多态性，就不该声明 virtual 析构函数。

# 条款8：别让异常逃离析构函数

## 01 为什么不希望析构函数抛出异常？

**析构函数的调用是不可控的**。如果析构函数抛出异常，那么程序的行为是未定义的，可能会导致内存泄露或其他严重的错误。这是因为在抛出异常的情况下，程序会跳过析构函数中尚未执行的部分，导致资源无法正确释放。

C++ 的最佳实践是，在析构函数中不要抛出异常。如果需要在析构函数中进行异常处理，可以使用 try-catch 来捕获异常，并在捕获异常后进行必要的清理工作。如果析构函数出现了异常，最好将该异常记录下来，并在析构函数之外处理，以确保程序的正常退出和资源的正确释放。

## 02 abort 函数的作用？

abort 函数用于以非正常的方式中止程序的执行。调用 abort 函数将导致程序退出，并生成一个核心转储，该转储包括了程序崩溃时的内存状态，以便于进行调试和诊断。

## 03 如何避免析构函数抛出异常？

**一是将异常吞掉**。一般而言，将异常吞掉是个坏主意，因为它压制了某些动作失败的重要信息，然而有时候吞掉异常也比负担“草率结束程序”或“不明确行为”带来的风险好。也就是说可以调用 abort 来将“不明确行为”吞掉。

**二是重新设计接口**。如果某个操作可能在失败时抛出异常，而又存在某种需要必须处理该异常，那么这个异常必须来自析构函数以外的某个函数，也就是提供一个普通函数执行可能导致异常的操作。

# 条款9：绝不在构造和析构过程中调用 virtual 函数

## 01 在构造函数调用 virtual 函数会怎样？

由于 base class 构造函数的执行更早于 derived class 构造函数， 当 base class 构造函数执行时 derived class 的成员函数尚未初始化。如果在此期间调用 virtual 函数下降至 derived classes 阶层，derived class 的函数几乎必然取用 local 成员变量，而那些成员变量尚未初始化。这将会造成不明确行为。

## 02 derived class 如何让 base class 中构造函数调用的函数改变？

场景：假设你有个 class 继承体系，用来塑模股市交易如买进、卖出的订单等等。这样的交易一定要经过审计，所以每当创建一个交易对象，在审计日记（audit log）中也需要创建一笔适当的记录。

一种做法是将 base class 构造函数调用的函数（log 函数）改为 non-virtual，然后要求 derived clas 构造函数传递必要信息给 base class 函数。不同的 derived class 都会调用 base class 的 log，但是调用结果不同。

# 条款10：令 operator= 返回一个 reference to *this

## 01 operator= 的作用是什么？

赋值拷贝，拷贝赋值是将一个对象复制到另一个对象的空间中，比拷贝构造难度更高。而且赋值拷贝还有返回值（`(a = b) 的返回值`），可以利用这个返回值实现连锁赋值（a=b=c）。

如果要实现连锁赋值，赋值操作符必须返回一个 reference 指向操作符的左侧的实参，也就是使用 `return *this` 语句。

## 02 为什么是 return *this，而不是 return this？

**this 是一个指向当前对象的指针，而 *this 表示当前对象本身的引用**。

需要注意的是，当使用引用返回对象本身时，需要避免对象引用指向被释放的内存或已经失效的对象。在实现对象的引用时，需要谨慎处理对象的生命周期，确保返回的引用不会出现悬空引用。

# 条款11：在 operator= 中处理“自我赋值”

## 01 拷贝赋值的自我赋值可能会存在哪些问题？

拷贝构造通常是先删除原有的指针，然后利用传入的指针来构造一个新的对象，再将新的对象赋值给原有的指针。可是，传入的指针和原有的指针可能指向同一对象，那就会导致对象被意外的释放。

## 02 如何确保拷贝赋值不但异常安全而且自我赋值安全？

首先记住原有的指针，然后令原有的指针指向新对象的地址，再将原来的指针指向的内容删除。这样做的话，如果创建新对象时抛出异常，原来的指针依然保持原状。

即时没有做证同测试（identity test），这段代码还是能够处理自我赋值。

## 03 copy and swap 是什么？

为你打算修改的对象做出一份副本，然后在那副本身上做一切必要的修改。若有修改动作抛出异常，原对象仍未改变状态。待所有改变都成功后，再将修改过的那个副本和原对象在一个不抛出异常的操作中置换（swap）。

这是一种常见并且较好的 operator= 撰写的办法（也是一种处理异常的好办法，如果修改失败就保持不变），首先以 by value 的方式传值，然后再将新创建的对象使用 swap 替换到当前对象。

```c++
Widget& Widget::operator=(Widget rhs){	// pass by value
    swap(rhs);	// 将 *this 的数据和 rhs 的数据互换。
    return *this
}
```

# 条款12：复制对象时勿忘其每一个成分

## 01 为 derived class 撰写 copy 函数有哪些注意事项？

这里的 copy 函数包括 copy assignment、copy 构造函数。

任何时候只要你承担起“为 derived class 撰写 copy 函数”的重责大任时，必须很小心地复制其 base 成分，那些成分往往是 private，你无法直接访问他们，你应该让 derived class 的 copying 函数调用相应的 base class 函数。

## 02 如何简化拷贝赋值和拷贝构造？

copying 函数往往有近似相等的实现本体，有些人可能希望让某个函数调用另一个函数避免代码重复。但不能使用 copying 函数调用另一个 copying 函数——令拷贝构造调用拷贝赋值。

消除重复代码的正确做法是**，建立一个新的成员函数给两者调用。这样的函数往往是 private 而且常被命名为 init**。