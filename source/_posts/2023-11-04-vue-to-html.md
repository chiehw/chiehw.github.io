---
title: 如何将Vue组件转换为HTML
categories: 编程杂货铺
abbrlink: c204f117
date: 2023-11-04 01:07:33
tags:
---

```js
// 设置参数
Component.param = ''
// 创建容器
const dom = document.createDocumentFragment()
const comp = createApp(Component).mount(dom)
console.log(comp.$el)
document.getElementById("myId").append(comp.$el)
```

- Vue3 组件转为HTML DOM节点：https://blog.csdn.net/hbiao68/article/details/131563015