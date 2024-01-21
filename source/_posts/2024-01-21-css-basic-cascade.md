---
title: CSS 基础回顾：层叠的基本概念
abbrlink: 55c26bca
date: 2024-01-21 23:36:11
categories:
tags:
---

## 前言

在解决传统编程问题时，你能通过报错或关键字来搜索，但在解决 CSS 问题时却很难搜索，因为样式之间相互关联，无法用一句简单的话来描述。CSS 会让你像下图一样抓狂：

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/jpg/css.gif" alt="css" style="zoom:50%;" />

要掌握 CSS，一定要理解其基础原理（如层叠、盒模型、基本单位），并且深入理解。这篇文章主要讲解「层叠 cascade」。

## 层叠的基本概念

CSS 的全称是 Cascade Style Sheet。层叠 Cascade 指一系列规则。这些规则可以决定——**当对同一个元素应用多个规则时，如何解决冲突**。在我们编写 CSS 的时候，经常会发现自己编写的样式没有生效，很可能和「层叠」有关。

什么时候会出现对同一个元素应用多个规则时？下面举一个简单的例子：

```html
<h1 id="page-title" class="title">Wombat Coffee Roasters</h1>
```

这里的 H1 标签就可能同时被多种选择器选中，最终只有 `#page-title` 生效。这里的例子只是层叠的一种类型——「优先级」。

```css
h1 {
  font-family: serif;
}

#page-title {
  font-family: sans-serif;
}

.title {
  font-family: monospace;
}
```

## 优先级、层叠顺序

层叠有三种常见的规则：优先级、层叠顺序。

优先级（[Cascading order](https://developer.mozilla.org/en-US/docs/Web/CSS/Cascade#cascading_order)）是最常见的一种层叠。它和 CSS 选择器紧密结合，将高优先级的样式应用到元素上。规则如下图所示，具体细节将在后面的文章展开。

![image-20240121225942130](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/jpg/cascading-order.png)

层叠顺序（Stacking）类似与 PS 中的图层，假设两个元素在屏幕的同一个位置，层叠顺序将决定哪个元素在上面。默认规则如下图所示，可以使用 z-index 属性进行调整。

![img](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/jpg/stacking-order.png)

## 题外话

<mark>一本书读十遍，读十本书</mark>。高中的时候，老师常说要回归课本，最近和前面那句话有相似的含义。在深入另一个领域之前，选取一本书作为课本，尽量将这本书读十遍，同时也大量阅读其他书籍（相关的）来完善这本书未提及的内容。按照这样的方式学习，可以拥有一个很扎实的知识体系。

[《深入解析 CSS》](https://book.douban.com/subject/35021471/)这本书可以作为 CSS 这一领域的课本。我的博文也正是基于这本书做拓展，将书中的内容进行补充和完善。