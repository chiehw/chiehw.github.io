---
title: v-model.number是什么？
categories: 程序人生
abbrlink: 32b12cdb
date: 2023-10-31 22:15:26
tags:
---

## 01 v-model.number是什么？

Vue 提供了3个 v-model 的修饰符，`.number` 可以让用户输入自动转换为数字。如果该值无法被 parseFloat 处理，将会返回原始值。`type=number` 会自动启用。

```js
exports[`compiler: transform v-model > modifiers > .number 1`] = `
"const _Vue = Vue

return function render(_ctx, _cache) {
  with (_ctx) {
    const { vModelText: _vModelText, withDirectives: _withDirectives, openBlock: _openBlock, createElementBlock: _createElementBlock } = _Vue

    return _withDirectives((_openBlock(), _createElementBlock(\\"input\\", {
      \\"onUpdate:modelValue\\": $event => ((model) = $event)
    }, null, 8 /* PROPS */, [\\"onUpdate:modelValue\\"])), [
      [
        _vModelText,
        model,
        void 0,
        { number: true }
      ]
    ])
  }
}"
`;
// 在调用 _withDirectives 函数的时候，多加了参数 number: true，可能在后面保存值的时候会做个转化。
```

- `.lazy`：当输入框失去焦点后触发change事件，由 change 时间来修改 model。
- `.trim`：去除用户输入内容中两端的空格。

## 参考

1. 表单输入绑定：https://cn.vuejs.org/guide/essentials/forms.html#number