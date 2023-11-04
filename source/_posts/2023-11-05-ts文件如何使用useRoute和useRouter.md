---
title: ts文件如何使用useRoute和useRouter
categories: 程序人生
abbrlink: ff11dacb
date: 2023-11-05 05:07:23
tags:
---

## 01 如何在 ts 文件中使用 useRoute？

useRoute 和 useRouter 是一个钩子，只能在 setup 中使用。在 js 中使用 router：

```js
import router from 'router/index'
```

使用 route：

```js
const route = router.currentRoute.value
```

