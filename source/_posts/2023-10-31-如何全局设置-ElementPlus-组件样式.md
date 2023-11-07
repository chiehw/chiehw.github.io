---
title: 如何全局设置 ElementPlus 组件样式
categories: 编程杂货铺
abbrlink: d4a0224
date: 2023-10-31 22:21:10
tags:
---

- 在 main.ts 中引入 `defaultElementPlus.ts`。

```ts
import './utils/defaultElementPlus' // ElementPlus全局样式设定
```

- 在  `defaultElementPlus.ts`  中对 ElementPlus 的默认样式进行设置。

```ts
import { ElTable, ElTableColumn } from 'element-plus'

ElTableColumn.props.align = { type: String, default: 'center' } // 表格列默认居中

export default {}
```

