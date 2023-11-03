---
title: 《精通 LevelDB》-1 基础理论
categories: 程序人生
tags:
  - 存储引擎
  - 《精通 LevelDB》
abbrlink: d33fb9f2
date: 2023-06-10 10:06:55
---

# 前言

> 同时参考了 书《精通 LevelDB》、“我叫尤加利”的《[leveldb 源码分析](https://youjiali1995.github.io/categories/#Storage)》博文系列、catkang 的《[庖丁解LevelDB](http://catkang.github.io/2017/01/07/leveldb-summary.html)》博文系列、LevelDB 官方的 [doc](https://github.com/google/leveldb/tree/main/doc)

## 01 Redis 和 LevelDB 的区别？

Redis 是基于内存的数据存储引擎，而 LevelDB 会将数据写入磁盘，LevelDB 被称为存储引擎更好。

# 第1章：初识 LevelDB

## 01 Google 的三大核心技术是什么？

- Bigtable：结构化的分布式存储系统，可拓展至 PB 级别的数据和数千台机器。
- GFS：Google 文件系统。
- MapReduce：是一种软件架构，用于大规模数据集的并行计算。

## 02 Bigtable 和 LevelDB 的关系？

Bigtable 依赖于 Google 其他项目所开发的未开源的库，所以无法公开。Sanjay Ghemawat 和 Jeff Dean 这两位来自 Google 的重量级工程师，为了能够将 Bigtable 的实现原理和技术细节分享给大众开发，于 2011 年基于 Bigtable 的原理，采用 C++ 开发了一个高性能的键-值数据库——LevelDB。

**LevelDB 是 Bigtable 的简化版或单机版**。

## 03 LevelDB 的核心优缺点？

- 优点：LevelDB 具有非常优异的读写性能。
- 缺点：LevelDB只支持单实例单线程，不具备相应的客户端访问模式，支持的数据类型不够丰富。

## 04 为什么基于 LevelDB 实现 RocksDB？

一般而言，数据库产品有两种访问模式可供选择。一种就是直接访问本地挂载的硬盘，即嵌入式的库模式；另一种是客户端通过网络访问数据服务器，并获取数据。

假设 SSD 硬盘的读写为 100us，机械硬盘的读写为 10ms，两台 PC 间的网络传输延时为 50us。如果是机械硬盘，客户端进行一次查询为 10.05ms，网络延时对于数据查询影响微乎其微；而在 SSD 时代，客户端进行一次查询约为 150us，和直接访问硬盘满了 50%，直接影响整体性能。

# 第2章：基础数据结构

## 01 LevelDB 为什么使用 Slice？

首先 Slice 比 string 更轻量，它只包含一个指向内存的指针和一个长度信息，而 string 包含指针、长度、容量等多个字段。这使得 Slice 在传递和处理时更加高效，可以减少内存占用和复制的开销。

其次，Slice 提供了更高的灵活性。Slice 对象可以包含任意二进制的数据，可以存储任何类型的键和值，而 string 只能存储 UTF-8 编码的字符串。

# 第3章：LevelDB 使用入门

## 01 什么是 LSM 树？

LSM 树（Log-Structured Merge Tree）是一种基于 LSM 架构的数据结构，它是用于高效存储和查询大量数据的数据结构。LSM 树主要用于处理写入操作较频繁、查询操作较少的场景，如日志存储、键值存储。

## 02 如何编译 LevelDB

先从 Github 下载 LevelDB 的源码，然后选择 1.2.0 的分支（最新的分支采用了 CMake）

```shell
make all
```

## 03 CMake 和 Make 的区别？

CMake 解决了一些 Make 存在的痛点，如 Makefile 文件的编写复杂、跨平台支持不足、自动依赖管理不够灵活。CMake 的优势在于它提供了一种简单而灵活的方式来管理构建过程，使得构建和部署变得更加容易和可靠。

同时，CMake 还提供了许多高级的特性，如模块化、交叉编译、自动化测试等，使得软件构建过程变得高效和灵活。

## 04 静态库和共享库的区别？

对于静态库，应用程序在编译时需要与静态库进行链接，编译后生成的二进制应用程序就包含了它所使用的与静态库文件相关的代码，这使得这类应用程序可以独立运行而不再依赖静态库。

对于动态库，在应用程序运行时才被加载与调用，并且共享库可以供多个应用程序调用。

## 05 函数参数顺序如何规范？

Google 发布的“C++编程风格指南”中，针对函数参数的顺序做了规范，一般输入参数在前，输出参数在后。在参数排序时，所有的输入参数置于输出参数之前。

# 第4章：总体架构与设计思想

## 01 LevelDB 和其他存储系统有什么区别？

通常存储系统采用哈希表或 B+ 树进行数据的存储，而 LevelDB 是基于 LSM 树（Log-Structed Merge Tree，日志结构合并树）进行存储。

## 02 LevelDB 的模块架构是怎样的？

![image-20230504154228639](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/05/upgit_20230504_1683186148.png)

LevelDB 总体模块架构主要包括接口 API （DB API 和 POSIX API）、Utility公共基础类、LSM树（LOG、SSTable、Memtable）三个部分。

## 03 LSM 树的核心思想是什么？

一般而言，在常规的物理硬盘存储介质上，**顺序写比随机写速度要快**，而 LSM 树正是充分利用了这一物理性质，从而实现对频繁、大量数据写操作的支持。

![image-20230504124407416](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/05/upgit_20230504_1683175447.png)

## 04 简述 LSM 树的读写过程？

![image-20230504130538873](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/05/upgit_20230504_1683176738.png)

**写操作**：当需要插入一条新的记录时，首先在 Log 文件末尾顺序添加一条数据插入的记录，然后将这个新的数据添加到驻留内存的 C0 树中，当 C0 树的数据大小达到某个阀值，则会自动将数据迁移、保留到磁盘中的 C1 树。

**读操作**：LSM 树将首先从 C0 树中进行索引查询，如果不存在，则转向 C1 中继续进行查询，直至找到最终的数据记录。直至找到最终的数据记录。

## 05 为什么要将磁盘中的数据拆成多层？

随着数据的不断写入，磁盘中的树会不断膨胀，**为了避免每次参与归并操作的数据量过大**，以及优化读操作的考虑，LevelDB 将磁盘中的数据拆分成称多层，每一层的数据达到一定容量后就会触发向下一层的归并操作，每一层的数据量比上一层成倍增长。

## 06 LSM 树的写过程？

LSM-tree 将磁盘的随机写转换成了顺序写，从而大大提高了写速度。为了做到这一点 LSM-Tree 的思路是将索引树结构拆成一大一小两棵树，较小的一个常驻内存，较大的一个持久化到磁盘，他们共同维护一个有序的 key 空间。写操作会首先操作内存中的树，随着内存中的树不断的变大，会触发与磁盘中树的归并操作，而归并操作本身仅有顺序写。

![image-20230505115210892](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/05/upgit_20230505_1683258731.png)

LevelDB 的写操作包括设置 key-value 和删除 key 两种（删除操作其实是向 LevelDB 插入一条标识为删除的数据）。对外暴露的写接口有 Put、Delete 和 Write，其中 Write 需要 WriteBatch 作为参数，而 Put 和 Delete 就是将当前操作封装到了一个 WriteBatch 对象，并调用 Write 接口。这里 WriteBatch 是一批写操作的集合，其存在的意义在于提高写入效率，并提供 Batch 内所有写入的原子性。

在 Write 函数中会首先用当前的 WriteBatch 封装一个 Write，代表一个完整的写入请求。LevelDB 加锁保证同一时刻只能有一个 Writer 工作。其他 Write 挂起等待，直到前一个 Writer 执行完毕后唤醒。

## 07 Writer 是如何写入的？

```c++
Status status = MakeRoomForWrite(my_batch == NULL);	// 为当前的写入准备 MemTable 空间。
uint64_t last_sequence = versions_->LastSequence();
Writer* last_writer = &w;
if (status.ok() && my_batch != NULL) {
  WriteBatch* updates = BuildBatchGroup(&last_writer);	// 尝试将当前等待的其他 Writer 中的写操作合并到当前的 WriteBatch 中，以提高效率。
  WriteBatchInternal::SetSequence(updates, last_sequence + 1);
  last_sequence += WriteBatchInternal::Count(updates);
  
  // 将当前的 WriteBatch 内容写入 Binlog 以及 Memtable。
  ......

  versions_->SetLastSequence(last_sequence);	// 所有值写入完成才更新 Sequence，保证 WriteBatch 写入过程中，不会被读请求看到，从而提供原子性。
}
```

## 08 为什么需要为写操作提前准备空间？

有以下两点原因：

- MemTable 已经写满则尝试切换到 immutable MemTable，生成新的 MemTable 供写入，并触发后台的 Immutable MemTable 向 Level0 SST 文件的 dump，Immutable Memtable Dump 不及时也会挂起当前写操作。
- Level0 层如果有过多的文件，就会延缓或挂起当前写操作

## 09 LSM 树的读过程？

首先，生成内部查询所用的 LookupKey，该 LookupKey 是由用户请求的 UserKey 拼接上 Sequence 生成的。其中 Sequence 可以由用户提供或使用当前最新的 Sequence，LevelDB 可以保证仅查询在这个 Sequence 之前的写入。

用生成的 LookupKey，依次尝试从 MemTable、ImmTable 以及 SST 文件中读取，直到找到。

## 10 在多层 SSTable 中如何查找 Key？

Manifest 中记录了每个文件的 Key 区间（利用 BFPTR 求得），我们可以很方便的直到某个 Key 是否在文件中（利用布隆过滤器）。

Level0 的文件由于直接由 ImmuTable Dump 产生，不可避免会相互重叠，所以需要依次查找。对于其他层次，由于归并过程保证了其相互不重叠且有序，二分查找的方式提供了更好的查询效率。

## 11 Compaction 操作有什么用？

Compaction 可以根据 Key 把数据分到不同的 SST 中，保证其不相互重叠且有序，同时删除过期的数据。Compaction 分为两个步骤：

1. CompactMemTable：MemTable 向 Level0 SST 文件的 Compaction
2. BackgroundCompaction：SST 文件向下层的 Compaction。

## 12 如何将数据从 MemTable 导入 SSTable？

CompactMemTable 函数会将 ImmuTable 中的数据整体 Dump 为 Level0 的一个文件，这个过程会在 Immutable MemTable 存在时被 Compaction 后台线程调度。

首先会获得一个 Immutable 的 Iterator 用来遍历其所有内容，创建一个新的 Level 0 SSTable 文件，并将 Iterator 读出的内容依次顺序写入该文件，之后更新元信息并删除 Immutable MemTable。

## 13 Level 0 的数据如何归并到 Level 1？

首先根据触发 Compaction 的原因以及维护的相关信息找到本次需要 Compact 的一个 SSTable 文件。对于 Level0 的文件比较特殊，由于 Level0 的 SST 文件由 MemTable 在不同时间 Dump 而成，所以可能有 Key 重叠。因此除该文件外还需要获取所有与之重叠的 Level 0 文件，这时我们得到一个包含一个或多个文件的文件集合，处于同一 Level。

在 Level+1 层获取所有与当前的文件集合有 Key 重复的文件，对得到的包含两层多个文件的文件集合进行归并操作，并将结果输出到 Level + 1 层的一个新的 SST 文件，归并过程中删除所有过期的数据。

最后删除之前文件集合里所有的文件，通过上述过程我们可以看到，这个新生成的文件其所在的 Level 不会跟任何文件有 Key 的重叠。

## 14 什么时候 Level 0 会归并到 Level 1？

SSTable 文件的 Compaction 可以由用户通过接口手动发起，也可以自动触发。LevelDB 触发 SST Compaction 的因素包括 Level 0 SSTable 的个数，其他 Level SSTable 文件的总大小，某个文件被访问的次数。

## 15 什么是多版本并发控制？

多版本并发控制 Multi Version Concurrency Control 是一种数据库管理系统中常用的并发控制技术，它可以让多个并发事务同时读取和修改数据库中的数据，而不会发生数据冲突。

在 MVCC 中，每个数据库对象都可以有多个版本。每一个都有一个时间戳，表示该版本的创建时间。当一个事务对一个对象修改时，它会创建一个新版本，并将该版本的时间戳设置为当前事务的时间戳，其他事务可以继续读取和修改原始版本，而不会受到正在进行的事务的影响。

# 第5章：公共基础类

## 01 Arena 内存池的作用？

Arena 主要表示一段较大且连续的内存空间，或称之为内存池。一般高性能的服务端应用或高性能的存储应用，通常都频繁对内存进行操作，使用内存池可以实现内存的高效利用。

# 第6章：Log 模块

## 01 WAL 是什么？

WAL 是 Write Ahead Log 的缩写，即预写日志，又叫做重做日志。这是一个追加修改、顺序写入磁盘的文件。在 LevelDB 中，我们称预写日志为 Log。

当向 LevelDB 写入数据时，只需要将数据写入内存中的 MemTable，但是内存是易丢失性存储。WAL 可以在保证程序崩溃时不会丢失数据。将 MemTable 成功写入 SSTable 后，相应的预写日志就可以删除了（每个 Log 文件对应着一个 MemTable）。

## 02 如何读取 Log 文件？

首先根据头部长度字段确定需要读取多少字节，然后根据头部类型字段确定该条记录是否已经完整读取，如果没有完整读取，继续按该流程进行，直到读取到记录的最后一部分，其头部类型为 LastType。

## 03 什么时候记录到 Log 文件？

LevelDB 每次进行**写操作**时，都需要 AddRecord 方法向 Log 文件写入此次增加的键 - 值对，并且根据 WriteOptions 中 Sync 的值来决定是否要进行刷新磁盘的操作（Linux 环境下执行 fsync 函数）。

LevelDB 也会将 **Manifest** 存入 Log 中，Manifest 是元数据清单，元数据包括比较器的名称、日志文件的序号、下一个文件的序号等信息，以便 LevelDB 恢复或重启时能够重建元数据。

## 04 什么时候从 Log  文件读取？

当启动 LevelDB 时，会检测是否存在没有删除掉的 Log 文件，如果有，则说明 Log 文件对应的 MemTable 数据未成功持久化到 SSTable，此时需要从该 Log 文件恢复 MemTable。

# 第7章：MemTable 模块

> 主要理解 SkipList 实现、MemTable 对 SkipList 的修改。

## 01 什么是 SkipList 跳表？

SkipList 这种数据结构是由 William Pugh 于 1990 年在 Communications of ACM June 1990 发表的，在 *Skip Lists: A Probabilistic Alternative To Balanced Trees* 中详细描述了它的工作原理。由论文标题可知，SkipList 的设计初衷是作为替换平衡树的一种选择。

## 02 SkipList 和红黑树对比？

**内存使用**：SkipList 中每个元素需要存储在多个层级中，因此需要更多的内存。具体来说，每个元素需要存储其在每个层级中的后继节点和前驱节点的指针中，这意味着 SkipList 在存储相同数量的元素是，需要更多的空间。

**复杂性**：在是线上，SkipList 相对于红黑树要简单一些。SkipList 的实现通常只需要使用链表和随机数生成器即可，而红黑树的实现需要考虑很多细节，例如节点的颜色、旋转操作等。

## 03 `std::numeric_limits<int>::min()` 作用是什么？

`std::numeric_limit<int>::min()` 和 INT_MIN 的返回值在语义上是相同的，都表示 int 类型的最小值。在使用时，可以根据具体的需求和代码风格选择哪种方式。

建议在 C++ 中使用 `std::numeric_limit<int>::min()`，因为它是标准库中的一部分，具有良好的可移植性和可读性。

## 04 `std::fill(begin(), end(), NIL)`作用是什么？

std::fill 是 C++ 标准库中的一个函数模板，用于将指定范围内的元素赋值为指定值。具体来说，这个函数模板是将 begin 和 end 中的所有元素赋值为 NIL。

## 05 如何在 SkipList 中插入节点？

插入的节点需要有多少个指针？插入后如何才能保证查找性能不下降（即维持采样的均衡）？

解决方法：将全局、静态的构建索引拆解成独立、动态的构建

# 第8章：SSTable 模块



# 附录：LevelDB 的演进

## 01 RocksDB 和 LevelDB 的区别与联系？

RocksDB 是基于 LevelDB 的数据库，创建 RocksDB 的初衷是能够**充分利用多个 CPU 核心并专门针对快速存储（例如 SSD）做了优化**。

RocksDB 和 LevelDB 都是 C++ 编写的库，而非一个分布式数据库，但是它作为存储引擎广泛应用到了多种主流的分布式数据库中，例如 Cassandra、MongoDB、SSDB、TiDB。

## 02 RocksDB 和 LevelDB 中 MemTable 的区别？

LevelDB 中的 MemTable 是一个 SkipList， 适用于写入和范围扫描，但并非所有场景都同时需要良好的写入和范围扫描，所以用 SkipList 优点大材小用。

RocksDB 的 MemTable 定义为一个插件式结构，可以是 SkipList，也可以是一个数组，还可以是一个前缀哈希表。因为数组是无序的，所以大批量写入比使用 SkipList 具有更好的性能，但不适用于范围查找，并且当内存中的数组需要生成 SSTable 时，需要进行再排序后写入 Level 0。前缀哈希表适用于读取、写入和再同一前缀下的范围查找。因此可以根据使用不同的 MemTable。

## 03 存储格式和具体实现之间的关系？

《庖丁解 LevelDB》中介绍了不同介质角色中数据的存储方式，但并没有讲解过多的代码细节。因为一旦有了具体的存储格式，**相关的代码不过就是在读写两端的序列化和反序列化**。

# 相关链接

- 我叫尤加利 - leveldb：https://youjiali1995.github.io/categories/#Storage
- leveldb 源码分析(二) – Architecture：https://youjiali1995.github.io/storage/leveldb-architecture/
- 漫谈 LevelDB 数据结构（一）：跳表（Skip List）：https://www.qtmuniao.com/2020/07/03/leveldb-data-structures-skip-list/
- 庖丁解 LevelDB：http://catkang.github.io/2017/01/07/leveldb-summary.html

# 推荐阅读

- O'Neil 的《The log-structured merge-tree》论文