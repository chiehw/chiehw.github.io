---
title: ElementUI input 文字居中
categories: 程序人生
abbrlink: f92d125d
date: 2023-10-31 22:14:05
tags:
---

## 01 如何实现 input 中的文字居中？

elementUI 的 input 组件共由 3 层组成：

```html
<div class=el-input>
    <div class=el-input__wrapper>
        <input>
    </div>
</div>
```

如果我们直接在 `el-input` 组件上添加 style，将会设置到第一层 div 上，而文字居中由最内层的 `input` 决定。所以我们需要想办法将样式调整到 `input` 中。

翻一翻文档，可以发现有个 `input-style` 可以设置内层 input 或 textarea 的样式。

```html
<Input placeholder="请输入内容" input-style={{ color: 'red' }} />
```

可以使用对象或者内敛样式。