---
title: vue-devtools-next 背后的原理
abbrlink: b5e25d84
date: 2024-03-07 23:40:33
categories:
- 前端
tags:
- vue
---

# 工程目录

在往下阅读之前我们需要先了解几个基本概念，`client` 指 devtools 中的 UI 界面，`user-app` 指被调试的 Vue 项目，`vite-server` 指 vite 服务。目前 devtools-next 还处于项目初期，项目中有一些文件夹作用不是很大，我根据自己阅读源码后将一些关键文件夹列出来。在下面的列表中，靠上方的子项目通常依赖于靠下方的子项目：

- vite：vite 的插件作为 devtool-next 的入口。
- client：devtools 的主要界面，负责和 `user-app` 和 `vite-server` 通信。`vite-server` 负责提供文件相关的 rpc 服务，`user-app` 提供调试相关的服务（查看和修改组件变量）。 
- overlay：为 `client` 提供容器，负责唤醒 client 以及提供调整 UI 大小的功能。
- core：为 `client`、`user-app`、`vite-server` 提供 RPC 支持、实现事件回调机制。
- devtool-kit：核心功能实现。

此外，还有一些子项目专门提供公共函数签名以及常量：

- shared：共用的工具类、常量。
- scheme：UI 相关的公共函数、常量。
- devtools-api：为插件提供 API 声明，主要实现在 devtools-kit 中。

最后 playground 内置了一些简单的功能，可以用来更方便的测试 devtools-next，因为该子项目在 package.json 中直接使用了当前 workspace 的 devtools-next。

# 数据流向图

<img src="https://blog-1256032382.cos.ap-nanjing.myqcloud.com/picgo/image-20240225235009167.png" alt="image-20240225235009167" width="500px"/>

在深入了解之前，先了解模块之间的相互关系会更清晰。User-App 和 Devtools Client 会通过 postMessage 或者 BroadcastChannel 来交换数据。Devtools Client 会通过 websocket 和 Vite Server 交换数据，相互进行 rpc 调用。

当 Devtools Client 以 iframe 嵌入到 User-App 中时，使用 postMessage 通信，postMessage 是 window 对象上的一个方法，可以安全的实现跨源通信。当 Devtools Client 以分离窗口的方式呈现时，使用 BroadcastChannel 通信，BroadcastChannel 可以让同源的不同窗口进行通信。

> PS：User-App 也会和 Vite Server 交换数据，但是不属于 Devtools Next 的研究范畴，所以没有在上图中画出来。

# User-App

## 载入 Devtools Frame

Devtools Next 的配置非常简单，只需要在 vite 插件中引入即可，无需修改项目代码来引入 Client 的源码，那它是怎么做到的呢？在 `packages/vite/src/vite.ts` 中，可以看到如下代码：

```javascript
const plugins = {
    transformIndexHtml(html) {
    	...
        attrs: {
          type: 'module',
          src: `${config.base || '/'}@id/virtual:vue-devtools-path:overlay.js`,
        },
        ...
	},
    transform(code, id) {
        ...
        code = `${code}\nimport 'virtual:vue-devtools-path:overlay.js'`
        ...
    }
}

```

也就是说，它通过 vite 的钩子在 html 中添加标签，或在代码中加载 overlay.js 文件来引入 Overlay、Client，随之完成一系列的初始化操作。

## 获取根组件

在 overlay.js 文件中通过 `devtools.init()` 来初始化全局的变量，如 `__VUE_DEVTOOLS_GLOBAL_HOOK__`，这个变量是获取 `Vue` 实例的关键点。在后文我们简称 `GLOBAL_HOOK`。

这里的 init 函数使用简单的发布-订阅机制的对象来初始化 `GLOBAL_HOOK`，这个对象实现了 on、off、once、emit 等方法，并且在这个对象上使用 on 函数设置了相关的事件回调，Vue 实例可以使用这个对象的 emit 方法来通知 devtools-next，下面是一些相关的 HOOK 名称：

```js
export enum DevToolsHooks {
  // internal
  APP_INIT = 'app:init',
  APP_UNMOUNT = 'app:unmount',
  COMPONENT_UPDATED = 'component:updated',
  COMPONENT_ADDED = 'component:added',
  COMPONENT_REMOVED = 'component:removed',
  COMPONENT_EMIT = 'component:emit',
  PERFORMANCE_START = 'perf:start',
  PERFORMANCE_END = 'perf:end',
  ADD_ROUTE = 'router:add-route',
  REMOVE_ROUTE = 'router:remove-route',
  RENDER_TRACKED = 'render:tracked',
  RENDER_TRIGGERED = 'render:triggered',
  APP_CONNECTED = 'app:connected',
  SETUP_DEVTOOLS_PLUGIN = 'devtools-plugin:setup',
}
```

Vue 会自动检测是否存在这个 `GLOBAL_HOOK`，如果存在就会在上面的 HOOK 中调用其 emit 方法来通知 devtool，且Vue 会将根组件赋值给这个全局变量。我们可以在 vue/core 项目中找到相关的代码：[检测 GLOBAL_HOOK](https://github.com/vuejs/core/blob/f66a75ea75c8aece065b61e2126b4c5b2338aa6e/packages/runtime-core/src/renderer.ts#L340)、[emit 事件](https://github.com/vuejs/core/blob/f66a75ea75c8aece065b61e2126b4c5b2338aa6e/packages/runtime-core/src/devtools.ts#L89)。

利用上面的基本原理，我们可以在生产环境下也打开 devtools。

```js
function openVue3(app_id = '#app'){
    const devtools = window.__VUE_DEVTOOLS_GLOBAL_HOOK__
    const app = $(app_id).__vue_app__
    const type = {
      Comment: Symbol("Comment"),
      Fragment: Symbol("Fragment"),
      Static: Symbol("Static"),
      Text: Symbol("Text"),
    },
    devtools.emit('app:init', app, app.version, type)
}

function openVue2(app_id = '#app') {
    const devtools = window.__VUE_DEVTOOLS_GLOBAL_HOOK__
    let Vue = $(app_id).__vue__.constructor
    while (Vue.super) { 
        Vue = Vue.super 
    }
    Vue.config.devtools = true
    devtools.emit('init', Vue)
}
```

参考链接：

- 强制打开线上 Vue 3 项目 Devtools 工具的一种方法：https://juejin.cn/post/7052955565944733709
- 开启vue项目生产环境的 Vue Devtools：https://juejin.cn/post/7081911875054600199
- enable-vue-devtools：https://github.com/EHfive/userscripts/blob/master/userscripts/enbale-vue-devtools/src/main.js

# 其他问题

## 如何将页面嵌入到已有项目中的？

这个功能的核心代码在 overlay 项目中，其中 createDevToolsContainer 函数会在 body 中添加一个 id 为 `__vue-devtools-container__` 的 div 标签。然后将 overlay 这个 app 挂载到 `__vue-devtools-container__`。

## 如何将 overlay 和 client 两个项目的 UI 结合？

在 overlay 中有一个函数叫做 useIframe 会创建一个 id 为 `vue-devtools-iframe` 的 iframe。这个函数的参数是 clientUrl，会最终指向这个 client 编译后的地址，client 项目只需要编译后以静态文件挂载即可。

## 事件回调

在 devtool-kit 实现了 devtool 的事件循环，其核心运用了 `hookable`。为什么要使用这个库进行事件回调？让函数能更灵活的，而不是硬编码。

## 如何实现 rpc？

vite-dev-rpc 提供了 createRPCServer 方法，可以传入参数来注册 rpc 函数。例如 `setupAssetsRPC` 会返回 getStaticAssets 函数，然后将这个函数注册到 server 端。再使用其提供的 createRPCClient 方法，创建 rpcClient，就可以调用远程的方法。更深层的原理需要继续阅读 vite-dev-rpc 的源码。

## 如何实现布局放大和缩小？

布局的核心源码在 overlay 中的 FrameBox 文件中，当在侧边栏点击鼠标左键时，标志位 isResizing 置为 true。使用事件监听器监听 `mousemove` 事件，根据窗口的位置来重置 localStore 中的高宽。

接下来可以看 `postion.ts` 文件中的代码，usePosition 可以传入 HTMLElement，然后将节点的高宽和 localStore 中高宽进行响应式的绑定。

## 如何查看 vue 组件中的变量？

在 client 的 pages 文件夹下，components 负责这部分代码的调用和展示，查看调用链，最终可以追踪到 `getInspectorState` 函数的参数 inspectorId 为 components。

```ts
function getComponentState(id: string) {
  bridgeRpc.getInspectorState({ inspectorId: 'components', nodeId: id }).then(({ data }) => {
    activeComponentState.value = normalizeComponentState(data)
  })
}
```

这个 INSPECTOR_ID 可以找到 registerComponentsDevTools 函数，这个函数注册了相关的处理方法，核心的处理方法为 `getComponentTree`。这个函数的参数为 `VueAppInstance`，可以传入 Vue 实例，然后遍历这棵实例树。

## 如何实现编辑数据？

同样也是在 devtool-kit 文件夹下，editInspectorState 函数负责修改 Vue 组件中的数据。最终会调用 editComponentState 函数。最终由 StateEditor 来实现状态的修改。

## RPC

**需要 Vite 支持 websocket**。从 vite 2.9 提供了 [Client-server Communication](https://vitejs.dev/guide/api-plugin#client-server-communication)，提供了客户端和服务端交互的工具。在 vite 的插件中，可以获取 websocket server，可以发送消息给所有的客户端。这样我们就可以轻松的获得 websocket 链接。在 client 中使用 `import.meta.hot` 获取 websocket 的 client。在 vite.config.ts 中， `configureServer(server)` 函数的 server.ws 就是 websocket 的 server。

**基于 websocket 的 rpc 框架 birpc**。这是一个轻量的 rpc 框架，[vite-dev-rpc](https://github.com/antfu/vite-dev-rpc) 将其和 `vite-hot-client` 做了封装，只需要使用 rpc client 即可调用服务端的函数。传递的消息格式如下所示：

```js
{
  "m": "add", // 方法名
  "a": [	// 参数
    97,
    41
  ],
  "i": "99Rbl9Im3PpZzBTlpbwSx",
  "t": "q"
}
```

## Bridge 类

这个类利用了适配器模式来封装 mitt 库，用于管理 JavaScript 中的事件。client 的事件都由 BridgeRpc 来转发，在 `registerBridgeRpc` 函数中注册处理函数。

## 跨文档消息 XDM(Cross-Document-Messaging)

在 devtools-next 中，使用 iframe 将 devtool client 的页面嵌入到用户的 HTML 中，用户的 app 和 devtool 的 app 需要通信的话，就需要用到 XDM 这项技术。在 overlay 中使用 postMessage 来通知 devtools app 初始化 devtool。

overlay 会被提前注入到用户程序中，等待 devtools app 加载完成后，再通过 postMessage 来通知 devtools app 启动。

在分离窗口的时候，使用 BroadcastChannel 来进行通信。在子页面中，使用 postMessage 通信。

## 查看和编辑组件信息

在 devtoolsBridge 类中，有两种 rpc。第一种是 viteRpc 用于和 vite 交互，获取服务端的文件等信息。第二种 rpc 用于和 client 交互，用于获取组件信息。

## 如何查看组件树

```ts
api.on.getInspectorTree(async (payload) => {
  if (payload.app === app && payload.inspectorId === INSPECTOR_ID) {
    const instance = getComponentInstance(devtoolsContext.appRecord!, payload.instanceId)
    if (instance) {
      const walker = new ComponentWalker({
        filterText: payload.filter,
        // @TODO: should make this configurable?
        maxDepth: 100,
        recursively: false,
      })
      payload.rootNodes = await walker.getComponentTree(instance)
    }
  }
})
```

核心源码在 user-app.ts 和 components.ts。在 `vueAppInit` 函数中，保存 Vue 的实例。