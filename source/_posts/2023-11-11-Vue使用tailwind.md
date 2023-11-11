---
title: Vue使用tailwind
categories: 编程
abbrlink: ef92871c
date: 2023-11-11 18:07:47
tags:
---

- 安装 tailwind

```bash
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

- 配置tailwind.config.js

```js
module.exports = {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

- 新建一个index.css

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

- 在main.js引入

```js
import { createApp } from "vue";
import App from "./App.vue";
import "./style/index.css"; //在此引入

createApp(App).mount("#app");
```

- 尝试使用 tailwind

```html
<template>
  <div class="text-center bg-gray-100 p-5">
    <p class="text-6xl text-red-700">Hello!</p>
    <h1 class="text-4xl text-green-500">Vite + TailwindCSS</h1>
  </div>
</template>
```

