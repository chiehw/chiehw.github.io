---
title: CSS：轻松解决层叠优先级
categories: 前端
tags:
  - CSS
abbrlink: 42b05cc5
date: 2024-02-07 09:23:14
---

写 CSS 的人都一定遇到过，为什么我的这个样式没有生效？打开开发者工具一看，自己的 CSS 选择器确实选中了这个样式，但是自己的样式被其他的选择器覆盖了。最佳的解决办法就是调整优先级，让我们来看看怎么做。

## 案例

下面我们来看一个非常简单的案例：

<iframe height="300" style="width: 100%;" scrolling="no" title="Untitled" src="https://codepen.io/chiehw/embed/dyrZxzE?default-tab=html%2Cresult" frameborder="no" loading="lazy" allowtransparency="true" allowfullscreen="true">
  See the Pen <a href="https://codepen.io/chiehw/pen/dyrZxzE">
  Untitled</a> by Chieh Wang (<a href="https://codepen.io/chiehw">@chiehw</a>)
  on <a href="https://codepen.io">CodePen</a>.
</iframe>
假设我们需要让这个 `title`  改为红色的背景，我们可能会写出如下代码

```css
.title {
  background: red;
}
```

这时就会产生疑惑了，为什么我设置的背景色没有生效？打开 F12 开发者工具，然后检查元素后就会知道真相：

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/css-devtools" alt="image-20240128094835435" width="500px" />

将鼠标放在 CSS 选择器上，就可以显示该选择器的优先级：

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/202401280952220.png" alt="image-20240128095209443" width="500px" />

可以简单的先将上面的`明确性：(1, 0, 0)`当成 100，下面的 `明确性：(0,1,0)`，当成 10，这样就能很容易的对比两个选择器的优先级的。

我们通常的编程环境是 VSCode，在 VSCode 中也可以将鼠标悬浮在选择器上，会得到同样的优先级：

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/image-20240128100037091.png" alt="image-20240128100037091" width="400px" />

这样做有什么好处呢？我们可以直观的知道自己的 CSS 选择器的优先级，从而写出更适合当前元素的选择器。这里的案例比较简单，了解原理后就能口算了。当涉及伪选择器、或更复杂的选择器时就能充分体现这种方法的优势了。

最后为我们给选择器添加上 `#page-title`，就能得到更高优先级的选择器了。

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/image-20240128100911274.png" alt="image-20240128100911274" width="400px" />

## 原理

这里摘抄一下《深入解析 CSS》对于优先级标记的描述：

> 一个常用的表示优先级的方式是用数值形式来标记，通常用逗号隔开每个数。比如，“1,2,2” 表示选择器由 1 个 ID、2 个类、2 个标签组成。优先级最高的 ID 列为第一位，紧接着是类，最后是标签。
>
> 选择器 `#page-header #page-title` 有 2 个 ID，没有类，也没有标签，它的优先级可以 用“2,0,0”表示。选择器 ul li 有 2 个标签，没有 ID，也没有类名，它的优先级可以用“0,0,2” 表示。
>
> ![image-20240128101331721](https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/image-20240128101331721.png)

## important 规则

不建议在这种情况使用  `!important` 。如果强行使用 `!important`，会让代码变得难以维护，有违《程序员的职业素养》中的==不行损害之事==。

更优雅的做法是将  `!important`  放在合适的工具类中，例如 hidden 工具类。

```css
.hidden {
	display: none !important;
}
```