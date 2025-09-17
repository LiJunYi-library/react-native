# withCustomAppDelegate 插件使用说明

## 功能描述

`withCustomAppDelegate` 插件允许你自定义 iOS AppDelegate 的启动流程，支持根据用户同意状态显示不同的界面，并可以自定义 HTML 内容。

## 安装使用

### 1. 基本使用

```javascript
// app.config.js
import { withCustomAppDelegate } from "@rainbow_ljy/react-native-plugins";

export default {
  name: "expoapp",
  plugins: [withCustomAppDelegate],
  // ... 其他配置
};
```

### 2. 自定义 HTML 内容

#### 选项1: 直接传入 HTML 内容

```javascript
// app.config.js
export default {
  name: "expoapp",
  plugins: [
    [
      withCustomAppDelegate,
      {
        customHtmlContent: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>隐私协议</title>
            <style>
              body { font-family: -apple-system; padding: 20px; }
              button { padding: 10px; margin: 5px; font-size: 16px; }
            </style>
          </head>
          <body>
            <h2>欢迎使用 App</h2>
            <p>请阅读以下协议...</p>
            <button onclick="nativeInitReactNative()">同意并继续</button>
            <button onclick="nativeInitEasyReactNative()">使用阉割版</button>
          </body>
          </html>
        `
      }
    ]
  ],
  // ... 其他配置
};
```

#### 选项2: 指定 HTML 文件路径

```javascript
// app.config.js
export default {
  name: "expoapp",
  plugins: [
    [
      withCustomAppDelegate,
      {
        customHtmlUrl: "/path/to/your/custom.html"
      }
    ]
  ],
  // ... 其他配置
};
```

#### 选项3: 使用默认 HTML 文件

如果不指定任何选项，插件将自动使用 `assets/html/privacyAgreement.html` 作为默认文件。

## 插件选项

| 选项 | 类型 | 描述 | 默认值 |
|------|------|------|--------|
| `customHtmlContent` | string | 直接传入的 HTML 内容 | - |
| `customHtmlUrl` | string | HTML 文件的完整路径 | - |
| 无选项 | - | 使用默认路径 `assets/html/privacyAgreement.html` | - |

## HTML 中的 JavaScript API

在 HTML 文件中，你可以使用以下 JavaScript 函数与原生代码交互：

### 可用的原生方法

- `nativeExitApp()` - 退出应用
- `nativeOpenWeb(url)` - 打开网页
- `nativeInitReactNative()` - 初始化 React Native（用户同意）

### 示例 HTML

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>隐私协议</title>
    <style>
        body { 
            font-family: -apple-system; 
            padding: 20px; 
            line-height: 1.6; 
        }
        button { 
            padding: 10px; 
            margin: 5px; 
            font-size: 16px; 
        }
    </style>
</head>
<body>
    <h2>欢迎使用 App</h2>
    <p>请阅读以下协议...</p>
    
    <button onclick="nativeExitApp()">退出 App</button>
    <button onclick="nativeOpenWeb('https://expo.dev')">打开网页</button>
    <button onclick="nativeInitReactNative()">同意并继续</button>

    <script>
        // 封装 JS 调用原生的方法
        function nativeExitApp() {
            NativeBridge.exitApp()
        }
        
        function nativeOpenWeb(url) {
            NativeBridge.openWeb(url)
        }
        
        function nativeInitReactNative() {
            NativeBridge.localStorageSet('userAgree', 'true')
            NativeBridge.initReactNative()
        }
    </script>
</body>
</html>
```

## 工作流程

1. **应用启动** - 检查用户同意状态
2. **已同意** - 直接启动 React Native
3. **已拒绝** - 启动限制版 React Native
4. **未选择** - 显示 HTML 协议页面让用户选择

## 注意事项

1. HTML 内容中的引号会被自动转义
2. 换行符会被转换为 `\n`
3. 确保 HTML 文件路径正确且文件存在
4. 自定义 HTML 内容优先级高于文件路径
5. 如果都不指定，将使用默认的 `assets/html/privacyAgreement.html`
