---
title: 《精通 LevelDB》-3 常见问题
date: 2023-06-10 10:41:18
categories: 程序人生
tags:
- 存储引擎
- 《精通 LevelDB》
---

# 第 1 章：LevelDB 背景

## 01 LevelDB 的设计思路与核心优势？

LevelDB 是依赖 Log Structed Merge Tree 的原理实现的，Log Structed Merge Tree 写性能非常好。其原理简单来说就是，磁盘的顺序写性能远高于随机写性能，而 Log Structed Merge Tree 可以将磁盘的随机写转化为顺序写，从而大大提升写速度。

RocksDB 在 LevelDB 的基础上针对 SSD 硬盘进行了优化，改进数据压缩，减少数据写入，增加 SSD 的寿命。

## 02 LevelDB 是如何提供可靠性的？

持久化的存储系统为了防止机器掉电或系统宕机造成正在写入的数据丢失，在写操作时通常都会先写日志文件，将要写入的数据先保存下来，若发生机器掉电或系统宕机，机器恢复后，可以读该日志文件恢复待写入的数据。LevelDB 也是如此。

LevelDB 在写入内存 MemTable 之前，先写入 Log 日志文件，再写入 MemTable。当发生异常情况时，均可以通过 Log 日志文件进行恢复。

## 03 LevelDB 是如何实现并发控制的？

LevelDB 使用 MVCC 实现并发控制，不支持事务，支持单个写操作和多个读操作同时执行：

- 每个成功的写操作会更新内部 db 维护的顺序递增的 sequence，sequence 会追加到 key 后同时保存。
- 读操作会使用最新的 sequence，只会读到小于等于自己的最大 sequence 数据。

## 04 LevelDB 为什么需要版本控制？

正常来说，当版本 A 升级到版本 B 后，版本 A 就是老版本了，这个时候实际上可以删掉的。但是，在 LevelDB 中，版本 A 可能还在服务读请求，因此，还不能扔掉，那么就需要同时保留这两版本 A、B，因此就形成了 A->B 这样的链接关系来记录，所有 VersionSet 就是利用链表来组织的，其中 Version dummy_version 是双向链表的头指针。当某个 Version 不再服务读请求之后，这个 Version 就会从双向链表移除。

## 05 为什么需要原子写 WriteBatch？

有时候，我们需要对象数据库连续执行操作。例如如果需要将 key1 对应的 value 移动到 key2 下，将连续调用 Put、Delete 和 Get 方法来修改/查找数据库。

```c++
std::string value;
 leveldb::Status s = db->Get(leveldb::ReadOptions(), key1, &value);
 if (s.ok()) s = db->Put(leveldb::WriteOptions(), key2, value);
 if (s.ok()) s = db->Delete(leveldb::WriteOptions(), key1);
```

这个时候如果进程在 Put Key2 后 Delete Key1 之前挂了，那么同样的 value 将会被存储在多个 Key 下。这时候如果使用 WriteBatch 就可以将整个操作组合成一个操作，从而避免出现上面的问题。

除了原子性，WriteBatch 也能加速更新过程，因为可以把一大批独立的操作添加到同一个 batch 中然后一次性执行。

# 第 2 章：Log Structed Merge Tree

## 01 LSM-Tree 的写过程是怎样的？

put 会首先追加到 WAL 日志中（Write Ahead Log，也就是真正写入之前先记录到日志，防止宕机丢失数据），接下来加到 C0 内存树，当 C0 层的数据达到一定大小，会触发 C0 层和 C1 层合并，类似归并排序，这个过程就是 Compaction。而归并操作本身也只是顺序写，合并出来的新的 new-C1 会替换掉原来的 old-C1。当 C1 层达到一定大小，则会继续和下层 Ck 合并。合并之后的旧文件都可以删掉，只留下新的。

由于 Key-Value 的写入可能重复，新版本需要覆盖老版本。比如，先写 a=10，再写 a=20，20 就是新版本。如果 a=10 的老版本已经到了 Ck 层了，这时候 C0 层来了个新版本 a=20，此时并不会去管底层文件有没有老版本 a=10，老版本 a=10 的清理是在合并 Compaction 的时候清理掉。写入过程基本只用到了内存，Compaction 是在后台异步完成的，不阻塞写入。

## 02 LSM-Tree 的读过程是怎样的？

由于最新的数据在内存的 C0 层，最老的数据在 CK 层，因此查询也是先查 C0 层，如果没有要查的 key，再查 C1，依次逐层查。由于一次查询可能需要多次查找操作，因此读操作会稍微慢一些。所以 LSM-tree 主要针对写多读少的场景。

读的顺序如下，只要读到对应的 key 就会停止：

- MemTable
- ImmuTable MemTable
- Level0 中单个文件中的键是有序的，但是 Level0 中所有文件可能会出现键重叠的情况，读取时从新到旧读取。
- 从 Level1 到 Level6，不只单个文件中的键是有序的，每个层级中的所有文件也不会有键重叠。每层最多只要读 1 个文件，按照层的顺序从低到高读取。

## 03 实现 LSM-Tree 的难点？

LSM-Tree 是一种设计思想，没有固定的实现方式，其中最重要的是 compaction 的实现。

Compaction 的实现涉及 MemTable 和 SSTable 间的合并方式、SSTable 的组织方式、 compaction 的时机。compaction 对读写性能起着至关重要的影响，它会清理无效的数据，能够降低磁盘的使用并降低读取的延时，但是也会带来极大的 IO 压力。

# 第 3 章：Log 模块

## 01 LevelDB 如何实现数据恢复？

持久化的存储系统为了防止机器掉电或系统宕机造成正在写入的数据丢失，在写操作时，通常都会先写日志，将要写入的数据先保存下来，若发生机器掉电或宕机，机器恢复后，可以读该日志文件恢复待写入的数据。LevelDB 也是如此，LevelDB 在写入内存 MemTable 之前，先写入 Log 日志文件，再写入内存 MemTable。当发生以下异常情况时，均可以通过 Log 日志文件进行恢复：

1. 写 Log 时，进程异常。
2. 写 Log 完成，写内存完成，进程异常。
3. 写操作完成（写 Log、写内存 MemTable 均完成），进程异常。
4. Immutable MemTable 持久化过程中进程异常。
5. 其他压缩异常。

当出现 1 异常时，数据库重启读取 Log 日志文件，发现 Log 日志文件异常，则认为此次用户写入操作失败，这样保障了数据的一致性。当 2、3、4 异常发生时，用户上次写入的数据、MemTable、Immutable MemTable 中的内存数据必然丢失，而数据库重启要读取 Log 日志文件，都可以重新恢复出用户上次写入的数据。这也意味着 Log 日志文件保留了所有的写入数据（包括旧数据），随着频繁的写操作，Log 日志文件必然随之膨胀。已经持久化的 SSTable 文件，不应该再回复，它只在数据库损坏情况下，修复数据库时用来恢复 SSTable 文件，此时，如果 Log 日志文件太大，势必恢复起来非常耗费时间。

# 第 4 章：MemTable 模块

## 01 MemTable 是如何组织和存储数据的？

MemTable 就是一个在内存中进行数据组织和维护的数据结构，其本质是一个跳表 SkipList，而之所以选用跳表这种数据结构，是由于其应用场景决定的。跳表 SkipList 这种数据结构的设计来源于数组的二分查找算法，把指针通过设计成数据的方式实现了数组二分查找的高效，使用了空间换时间的思想。

跳表 SkipList 在查找效率上可比拟二叉查找树，绝大多数情况下时间复杂度 O(logn)，这契合 LevelDB 快速查找 Key 的需要。在 MemTable 中，所有数据按用户自定义的排序方法排序后有序存储，当其数据容量达到阈值（默认是 4 MB），则其转换为一个只读的 MemTable，同时创建一个新的 MemTable 供用户继续读写。

# 第 5 章：SSTable 模块

## 01 SSTable 文件数据格式是怎样的？

- Data Block：是用来存储数据的，Data Block 有多个，LevelDB 将数据存放在多个 Data Block  里面，即：每个 SSTable 文件包含多个 DataBlock。每个 DataBlock 有一定的大小，并且按照键的顺序进行排序，后一个 DataBlock 的第一个 Key 大于前一个 DataBlock 的最后一个 Key。
- Filter Block：这是为了快速判断一个 Key 是否存在于该 SSTable 文件。当查找一个 Key 的时候，如果 Key 不在内存 MemTable 中，那就需要遍历 SSTable 文件，这显然太慢了。为了提高查找效率，于是就设计了一个 Filter Block 在 SSTable 文件中，这样就提高了读取的速度。可以有多个 Filter Block，目前只有一个布隆过滤器。
- Meta Index Block：它记录了 Filter Block 对象的偏移起始位置和整个 Filter Block 的大小。
- Index Block：它记录了 DataBlock 对象的偏移起始位置和整个 DataBlock 的大小。
- Footer：它记录了一个文件最关键的两个信息 Meta Index Block 和 Index Block。

![image-20230605145712872](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/06/upgit_20230605_1685948233.png)

## 02 为什么要在 SSTable 中放置布隆过滤器？

布隆过滤器是一种概率型的数据结构，特点是高效的插入和查询，它的作用是为了快速判断一个 Key 是否存在。这不是精确判断：如果一个 Key 判断存在，实际不一定存在；但是如果判定一个 Key 不存在，那就一定不存在，其结果是假阳性。利用这个特性，可以快速判断一个 Key 是否存在，如果不存在就不需要再去查找了，直接返回错误。如果判断存在，则需要进一步判断 Key 是否存在。

DataBlock 数据量太大，可能不会缓存在内存中，这样就需要一次磁盘 IO，查询效率必然不高。布隆过滤器就可以解决这个问题，布隆过滤器比较小，可以缓存在内存中，这样就可以通过布隆过滤器快速判断对应的键有没有在这个 SSTable 里。**选择布隆过滤器是因为布隆过滤器的空间占用非常小，可以加载到内存中，进行快速的判定**。

LevelDB 采用了多个布隆过滤器，默认情况下，每 2 KB的数据开启一个布隆过滤器，因此，布隆过滤器也必然是一个数组结构。

# 第 6 章：多版本管理与 Compaction 模块

## 01 VersionEdit、Version、VersionSet 的关系？

VersionSet 是 LevelDB 中管理和维护所有版本的主要数据结构，而 Version 和 VersionEdit 是 VersionSet 中关键的元素。当需要创建新的 Version 时，客户端会创建出新的 VersionEdit，并将其提交给 VersionSet。VersionSet 会将这个 VersionEdit 应用到自己的状态中，从而创建一个新的 Version。当需要删除或修改 Version 时，客户端也会创建一个相应的 VersionEdit，并将其提交给 VersionSet，以便进行相应的操作。

LevelDB 使用版本 Version 来管理每个层级拥有的文件信息，每次执行 Compaction 操作之后会生成一个新的版本。生成新版本的过程中，LevelDB 会使用一个中间状态的 VersionEdit 来临时保存信息，最后将当前版本和中间状态的 VersionEdit 合并处理后生成一个新的版本，并将最新版本赋值为当前版本。

一系列的版本构成一个版本集合，LevelDB 中版本集合 VersionSet 是一个双向的链表结构。

## 02 什么时机触发 Compaction？

写操作：如果内存中的 MemTable 写入超过限制，则会从 MemTable 生成一个 SSTable 并且将其写入 Level 0，此时 Level 0 文件可能会超出限制，从而触发 Compaction。

读操作：当无效读取次数 allowed_seeks 过大。

> 假设 Level n 层包含一个名称为 f1 的文件，该文件的键范围为 [L1, H1]，n+1 层某个文件 f2 的键范围为 [L2, H2]。当我们查找 key1 时，假设 key1 即位于 [L1, H1] 和 [L2, H2] 的范围，则先查找 Level n 层的 f1 文件，如果没有查到，则继续查找 Level n+1 层的 f2 文件，此时 f1 文件的读取就算**一次无效读取**。

## 03 有哪些策略可以触发 Compaction？

策略 1：通过判断层级中文件个数 Level 0 或总文件大小（Level 1 ~ Level 5）来计算得出 compaction_score 和 compaction_level_。

策略 2：通过判断文件无效读取次数 allowed_seek 的大小。

## 04 Compaction 的流程是怎样的？

在 Compaction 过程中，首先对参与压缩的 SSTable 文件按 key 进行归并排序，然后将排序后结果写入到新的 SSTable 文件中，删除参与 Compaction 的旧 SSTable 文件。

![image-20230605144749367](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/2023/06/upgit_20230605_1685947669.png)

## 05 为何会有 Compaction？它的作用是什么？

LevelDB 的写操作都是追加 Append 操作，只要写入 MemTable 即可，如果带 Sync 同步的，也只是把写入日志 Log 的数据刷新到磁盘上而已。这就意味着同一个 key 的增删改全部记录下来了，数据的冗余度必然直线上升，庞大的数据冗余必然带来大量的文件，读的操作成本很高，读性能很差，精简文件的数量就十分必要。

从 SSTable 的角度来看，何为 SSTable？就是 Sorted String Table，有序的固化表文件，有序体现在 Key 是按序存储的，也体现在除了 Level-0 之外，其他 Level 中的 SSTable 文件之间也是有序的，即：Key 不重叠。这就要求有专门的工程来做 Key 的合并排序工作，这也是增加 Compaction 的必然要求。

所以 Compaction 的作用：1）清理过期的数据；2）维护数据的有序性。

# RocksDB

## 01 RocksDB 在哪些地方优于 LevelDB？

- 更好的性能：RocksDB 在性能方面表现更优秀，尤其是在写入操作和随机读取操作方面。
- 更好的可拓展性：RocksDB 支持多种压缩算法和压缩格式，可以节约存储空间的同时，提高读取性能和吞吐量。
- 更丰富的功能：RocksDB 支持多种功能和特性，可以满足更多的场景和需求。例如多层缓存、动态调节缓存大小、数据分区、高级查询。

## 02 RocksDB 如何优化写过程？

- 优化 Wait：减少条件变量的使用。从 FUTEX_WAIT 和 FUTEX_WAKE 平均需要 10 us 的时间，这个代价太大了。通过下面 3 种方法：
  - Loop：通过循环忙等待一段有限的时间（大约 1us），绝大多数情况下，这 1us 忙等足以让 state 条件满足。忙等待占用 CPU，但不会发生上下文切换，所以减小了额外的开销。
  - Short-Wait：通过让出 CPU，减少线程占用和等待的时间。大约 9 us。
  - Long-Wait：通过利用 CondVar 来等待。

## 03 Page Cache 是什么？

Page Cache 是通过将磁盘中的数据缓存到内存中，从而减少磁盘 IO 操作，从而提升性能。此外，还要确保 Page Cache 中数据的更改能够被同步到磁盘上（Page Write Back，即 Page 回写）。

Page Cache 由内存中的物理 Page 组成，其内容对应磁盘上的 Block，Page Cache 的大小是动态变化的，可以扩大，也可以在内存不足时缩小，Cache 缓存的存储设备被称为后备存储（Backing Store）。一个 Page 通常包含多个 Block，这些 Block 不一定是连续的。

# 相关链接

- 01| LevelDB架构分析：https://zhuanlan.zhihu.com/p/436037845
- 02| LevelDB SSTable文件数据布局：https://zhuanlan.zhihu.com/p/458192046
- LevelDB：https://youjiali1995.github.io/categories/#Storage
- RocksDB 源码分析 – I/O：https://youjiali1995.github.io/rocksdb/io/
- 【rocksdb源码分析】写优化之JoinBatchGroup：https://zhuanlan.zhihu.com/p/30717524