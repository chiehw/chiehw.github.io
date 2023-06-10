---
title: 《Effective C++》-6 定制 new
date: 2023-06-10 10:05:03
categories: 程序人生
tags:
- C++
- 《Effective C++》
---

# 条款 49：了解 new-handler 的行为

## 01 new-handler 是什么？

当 operate new 抛出异常以反映一个未获满足的内存需求之前，它会先调用一个客户指定的错误处理函数，一个所谓的  new-handler。为了指定这个用以处理内存不足的函数，客户必须调用 set_new_handler，那是声明于 `<new>` 的一个标准程序库函数。

## 02 如何为 class 定制 new-handler？

令每一个 class 提供自己的 set_new_handler 和 operator new。

其中 set_new_handler 使客户得以指定 class 专属的 new-handler（就像标准中的 set_new_handler 允许客户指定 global new-hanler），至于 operator new 则确保分配 class 对象内存的过程中以 class 专属的 new-handler 替换 global new-handler。

# 条款 50：了解 new 和 delete 合理的替换时机

## 01 为什么要替换编译器提供的 new 和 delete？

- **用来检测运用上的错误**。如果 new 所得的内存，delete 掉却不幸失败，会导致内存泄露。如果 new 所得内存身上多次 delete 则会导致不确定行为。
- **强化效能**。编译器所带的 new 和 delete 主要用于一般目的。通常而言，定制版的 new 和 delete 性能胜过缺省版本，更快，需要的内存更少，最高可省 50%。对某些应用程序而言，将旧有的 new 和 delete 替换为定制版本，是获得重大性能提升的办法之一。
- **为了收集使用上的统计数据**。

# 条款 51：编写 new 和 delete 时需固守常规

## 01 编写 new 和 delete 有哪些注意事项？

operator new 应该内含一个无穷循环，并在其中尝试分配内存，如果它无法满足内存需求，就该调用 new-handler。它也应该有能力处理 0 byte 申请。Class 专属版本则应该处理“比正确大小更大的错误申请”。

operator delete 应该在收到 null 指针时不做任何事，class 专属版本应该处理比正确大小更大的错误申请。

# 条款 52：写了 placement new 也要写 placement delete

## 01 什么是 placement new？

如果 operator new 接受的参数除了一定会有的那个 size_t 之外还有其他，这边是个所谓的 placement new。众多 placement new 版本中特别有用的一个是“接受一个指针指向对象所被构造之处”。这个版本的 new 已被纳入 C++ 标准程序库，你只要` #include<new>` 就可以取用它。这个 new 的用途之一是负责在 vector 的未使用空间上创建对象。

placement new 意味着任意额外参数的 new。

## 02 只写 placement new 会怎样？

如果一个带额外参数的 operator new 没有带相同额外参数的对应版 operator delete，那么当 new 的内存分配动作需要取消并恢复旧观时就没有任何 operator delete 被调用。因此，为了消弭稍早代码中的内存泄露，有必要声明一个 placement delete。

如果没有这样做，你的程序可能会发生隐微而时断时续的内存泄露。

# 条款 53：不要轻忽编译器的警告

## 01 如何看待编译器的警告？

- 严肃对待编译器发出的警告信息，努力在你的编译器的最高警告级别争取无任何警告的荣誉。
- 不要过度依赖编译器的报警能力，因为不同的编译器对待事情的太不并不相同。一旦移植到别的编译器上，你原本依赖的警告信息可能会消失。

# 条款 54：让自己熟悉包括 TR1 在内的标准程序库

## 01 TR1 为什么那么重要？

TR1 代表 “Technical Report 1”，那是 C++ 程序库工作小组对该份文档的称呼。标准委员会保留了 TR1 正式铭记于 C++0x 之前的修改权。

就所有意图和目标而言，TR1 宣示了一个新版 C++ 的来临，我们可能称之为 Standard C++ 1.1.不熟悉 TR1 技能而却奢望成为一位高效的 C++ 程序员是不可能的，因为 TR1 提供的技能几乎对每一种程序库和每一种应用程序都带来利益。

## 02 TR1 和 Boost 的关系？

TR1 自身只是一份规范。为了获得 TR1 提供的好处，你需要一份实物。一个好的实物来源是 “Boost”。

