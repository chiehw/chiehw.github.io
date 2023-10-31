---
title: ElementUI 事件添加额外自定义参数
date: 2023-10-31 22:16:42
categories:
tags:
---

## 01如何自定义参数？

正常情况下，直接不加括号就能接收参数 `@change=handleChange`。想要增加自定义的参数，就会无法收到自定义参数 `@change=handleChange(param)`。

不过可以在自定义参数之前加入 $event 变量，再传入其他值，这样的话，就能获得组件的自定义参数。`@change=handleChange($event, param)`。

## 02 $event的原理？

`@change=handle` 在 vue 中会被解析为

```javascript
const compVNode = {
    type: xxx,
    props:{
        onChange: handler
    }
}
```

在调用 emit 函数的时候，会将自定义的参数传进去：

```js
if(handler){
    handler(...payload)
} else {
    console.log('事件不存在')
}
```

> 虽然没有看源码，但是我猜 `handleChange($event, param)` 应该是被解析成函数和参数后分开存储，而不是被直接调用。

简单翻了一下源码：

```js
test('inline statement w/ prefixIdentifiers: true', () => {
    // html：<div @click="foo($event)"/>
    const { node } = parseWithVOn(`<div @click="foo($event)"/>`, {
      prefixIdentifiers: true
    })
    expect((node.codegenNode as VNodeCall).props).toMatchObject({
      properties: [
        {
          key: { content: `onClick` },
          value: {
            type: NodeTypes.COMPOUND_EXPRESSION,
            children: [
              // 默认参数是 $event
              `$event => (`,
              {
                type: NodeTypes.COMPOUND_EXPRESSION,
                children: [
                  // foo 函数
                  { content: `_ctx.foo` },
                  `(`,
                  // 自定义 payload
                  { content: `$event` },
                  `)`
                ]
              },
              `)`
            ]
          }
        }
      ]
    })
  })
```

