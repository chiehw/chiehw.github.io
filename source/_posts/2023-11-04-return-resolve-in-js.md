---
title: return resolve() 含义
categories: 程序人生
abbrlink: 1a431fac
date: 2023-11-04 01:09:13
tags:
---

## 01 promise解决了什么问题

Promise 是异步编程的一种解决方案。

- Promise 是一个构造函数，对外提供统一的 API（.then，catch），对内提供方案（resolve 调用外部的then，reject 调用外部的 catch）。

## 02 resolve 有什么用？

平时只会用最简单的 Promise。开发时，设计 Promise 时，resolve 代表 then，reject 代表 catch。

```js
Request(){
    return new Promise((resolve, reject) => {
    	this.get(url, params, (res) => {
            resolve(res)
        })
    })
}
```

## 03 return resolve()含义

如果 Promise 任务结束后，需要进入下一个任务，可以使用 return 的方式进入下一个 then，此时 return 有一下特点：

1. 返回 Promise，可以继续使用 .then 可以连续调用（不过下一个 .then 的参数由新的 Promise 决定）。
2. 如果返回其他值（如 resolve），也可以在 .then 获取到。

根据 A 接口的结果调用 B 接口，再调用 C 接口。

```js
interfaceA()
  .then((res) => {
    console.log(res);
    return interfaceB();
  })
  .then((res) => {
    console.log(res);
    return interfaceC();
  })
  .then((res) => {
    console.log(res);
  });
```

## 参考

1. axios因token过期导致弹出多条信息提示，简单处理解决！：https://blog.csdn.net/m0_46156566/article/details/113976916
1. 从 promise 到底要不要加 return 开始：https://juejin.cn/post/6879692911680684040
1. JavaScript Promise 全介紹：https://www.casper.tw/development/2020/02/16/all-new-promise/

