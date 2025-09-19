// StartupViewController.swift
import UIKit
import WebKit

public class StartupViewController: UIViewController {
    
    // MARK: - Properties
    private var webView: WKWebView!
    private let margin: CGFloat = 20.0
    private var customHtmlContent: String?
    private var appDelegate: AnyObject?
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 隐藏导航栏，实现全屏效果
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 恢复导航栏
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Private Methods
    private func setupWebView() {
        // 创建 WKWebView 配置
        let webConfiguration = WKWebViewConfiguration()
        
        // 设置 message handler，用于 JS 调用原生
        webConfiguration.userContentController.add(self, name: "exitApp")
        webConfiguration.userContentController.add(self, name: "openWeb")
        webConfiguration.userContentController.add(self, name: "initReactNative")
        webConfiguration.userContentController.add(self, name: "localStorageSet")
        webConfiguration.userContentController.add(self, name: "localStorageGet")
        webConfiguration.userContentController.add(self, name: "localStorageRemove")
        webConfiguration.userContentController.add(self, name: "localStorageClear")
        webConfiguration.userContentController.add(self, name: "getStateBarHeight")
        
        // 创建全屏 WebView
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        // 添加到主视图
        view.addSubview(webView)
        
        // 设置全屏约束
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 加载 HTML 内容
        loadWebContent()
    }
    
    private func loadWebContent() {
        // 加载 HTML 字符串（使用自定义内容或默认内容）
        let htmlContent = customHtmlContent ?? getDefaultHtmlContent()
        
        let injectedScript = """
            // 生成唯一事件ID的工具函数
            function generateEventId() {
                return 'event_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            }
            
            // 事件回调存储
            window._nativeCallbacks = {};
            
            // NativeBridge 兼容层
            window.NativeBridge = {
                exitApp: () => {
                    window.webkit?.messageHandlers?.exitApp?.postMessage(null);
                },
                openWeb: (url) => {
                    window.webkit?.messageHandlers?.openWeb?.postMessage(url);
                },
                initReactNative: () => {
                    window.webkit?.messageHandlers?.initReactNative?.postMessage(null);
                },
                localStorageSet: (key, value) => {
                    window.webkit?.messageHandlers?.localStorageSet?.postMessage({
                        key: key,
                        value: value
                    });
                },
                localStorageGet: (key, callback) => {
                    const eventId = generateEventId();
                    window._nativeCallbacks[eventId] = callback;
                    window.webkit?.messageHandlers?.localStorageGet?.postMessage({
                        key: key,
                        eventId: eventId
                    });
                },
                localStorageRemove: (key) => {
                    window.webkit?.messageHandlers?.localStorageRemove?.postMessage({
                        key: key
                    });
                },
                localStorageClear: () => {
                    window.webkit?.messageHandlers?.localStorageClear?.postMessage(null);
                },
                getStateBarHeight: (callback) => {
                    const eventId = generateEventId();
                    window._nativeCallbacks[eventId] = callback;
                    window.webkit?.messageHandlers?.getStateBarHeight?.postMessage({
                        eventId: eventId
                    });
                }
            };
            
            // 事件回调处理函数
            window.onNativeEventReceived = (eventId, data) => {
                if (window._nativeCallbacks[eventId]) {
                    window._nativeCallbacks[eventId](data);
                    delete window._nativeCallbacks[eventId];
                }
            };
        """
        
        let finalHTML = injectScriptIntoHTML(htmlContent, script: injectedScript)
        webView.loadHTMLString(finalHTML, baseURL: nil)
    }
}

// MARK: - Helper Functions
func injectScriptIntoHTML(_ html: String, script: String) -> String {
    let headCloseTag = "</head>"
    let scriptTag = "<script>\n\(script)\n</script>"
    
    if html.contains(headCloseTag) {
        // 插入到 </head> 前面
        return html.replacingOccurrences(of: headCloseTag, with: scriptTag + headCloseTag)
    } else {
        // 没有 <head>，插入到 <body> 前或开头
        return scriptTag + "\n" + html
    }
}

// MARK: - WKNavigationDelegate
extension StartupViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 允许所有导航
        decisionHandler(.allow)
    }
}

// MARK: - WKScriptMessageHandler
extension StartupViewController: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "exitApp":
            exitApp()
            
        case "openWeb":
            if let urlString = message.body as? String,
               let url = URL(string: urlString) {
                openWeb(url: url)
            }
            
        case "initReactNative":
            initReactNative()
            
        case "localStorageSet":
            if let data = message.body as? [String: Any],
               let key = data["key"] as? String,
               let value = data["value"] as? String {
                localStorageSet(key: key, value: value)
            } else {
                print("localStorageSet: 无效的参数格式")
            }

        case "localStorageGet":
            if let data = message.body as? [String: Any],
               let key = data["key"] as? String,
               let eventId = data["eventId"] as? String {
                let value = localStorageGet(key: key)
                // 通过 evaluateJavaScript 将结果返回给 JavaScript
                webView.evaluateJavaScript("""
                    window.onNativeEventReceived('\(eventId)', {
                        key: '\(key)',
                        value: '\(value)'
                    });
                """)
            } else {
                print("localStorageGet: 无效的参数格式")
            }

        case "localStorageRemove":
            if let data = message.body as? [String: Any],
               let key = data["key"] as? String {
                localStorageRemove(key: key)
            } else {
                print("localStorageRemove: 无效的参数格式")
            }

        case "localStorageClear":
            localStorageClear()

        case "getStateBarHeight":
            if let data = message.body as? [String: Any],
               let eventId = data["eventId"] as? String {
                let height = getStateBarHeight()
                // 通过 evaluateJavaScript 将结果返回给 JavaScript
                webView.evaluateJavaScript("""
                    window.onNativeEventReceived('\(eventId)', {
                        height: \(height)
                    });
                """)
            } else {
                print("getStateBarHeight: 无效的参数格式")
            }
     
            
        default:
            print("未知消息: \(message.name)")
        }
    }
}

// MARK: - Native Methods
extension StartupViewController {
    private func exitApp() {
        // 退出 App（iOS 不允许强制退出，但可以提示用户）
        let alert = UIAlertController(title: "退出应用", message: "确定要退出吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { _ in
            exit(0) // ⚠️ 苹果不推荐，但可用于调试或 kiosk 模式
        })
        present(alert, animated: true)
    }
    
    private func openWeb(url: URL) {
        let webVC = WebViewController()
        webVC.urlString = url.absoluteString
        let nav = UINavigationController(rootViewController: webVC)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true)
    }
    
    // 设置 AppDelegate 的方法
    public func setAppDelegate(_ delegate: AnyObject) {
        self.appDelegate = delegate
    }
    
    // 设置自定义 HTML 内容的方法
    public func setCustomHtmlContent(_ htmlContent: String) {
        self.customHtmlContent = htmlContent
    }
    
    // 获取默认 HTML 内容的方法
    private func getDefaultHtmlContent() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>协议</title>
            <style>
                body { 
                    font-family: -apple-system; 
                    padding: 20px; 
                    line-height: 1.6;
                    margin: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    color: white;
                }
                .container {
                    max-width: 600px;
                    margin: 0 auto;
                    padding: 20px;
                }
                h2 {
                    text-align: center;
                    margin-bottom: 30px;
                    font-size: 28px;
                }
                .button-group {
                    display: flex;
                    flex-direction: column;
                    gap: 15px;
                    margin-top: 30px;
                }
                button { 
                    padding: 15px 20px; 
                    font-size: 16px;
                    border: none;
                    border-radius: 8px;
                    background: rgba(255, 255, 255, 0.2);
                    color: white;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    backdrop-filter: blur(10px);
                }
                button:hover {
                    background: rgba(255, 255, 255, 0.3);
                    transform: translateY(-2px);
                }
                .back-button {
                    position: fixed;
                    top: 20px;
                    left: 20px;
                    background: rgba(0, 0, 0, 0.5);
                    padding: 10px 15px;
                    border-radius: 20px;
                    font-size: 14px;
                }
                .status-info {
                    background: rgba(255, 255, 255, 0.1);
                    padding: 15px;
                    border-radius: 8px;
                    margin: 20px 0;
                    backdrop-filter: blur(10px);
                }
            </style>
        </head>
        <body>
            <button class="back-button" onclick="goBack()">← 返回</button>
            
            <div class="container">
                <h2>欢迎使用 App</h2>
                
                <div class="status-info">
                    <p>请阅读以下协议并选择您的操作...</p>
                </div>
                
                <div class="button-group">
                    <button onclick="nativeInitReactNative()">✅ 同意并初始化RN</button>
                    <button onclick="nativeInitEasyReactNative()">⚠️ 不同意但继续</button>
                    <button onclick="nativeOpenWeb()">🌐 打开网页</button>
                    <button onclick="getStatusBarHeight()">📏 获取状态栏高度</button>
                    <button onclick="getUserAgreeStatus()">📋 查看用户同意状态</button>
                    <button onclick="nativeExitApp()">❌ 退出 App</button>
                </div>
            </div>

            <script>
                // 回退功能
                function goBack() {
                    if (window.history.length > 1) {
                        window.history.back();
                    } else {
                        // 如果没有历史记录，可以调用原生方法
                        console.log('没有历史记录可回退');
                    }
                }
                
                // 封装 JS 调用原生的方法
                function nativeExitApp() {
                    NativeBridge.exitApp()
                }
                
                function nativeOpenWeb() {
                    const url = 'https://expo.dev';
                    NativeBridge.openWeb(url)
                }

                function nativeInitEasyReactNative() {
                    NativeBridge.localStorageSet('userAgree', 'false')
                    NativeBridge.initReactNative()
                }
                
                function nativeInitReactNative() {
                    NativeBridge.localStorageSet('userAgree', 'true')
                    NativeBridge.initReactNative()
                }
                
                // 示例：使用 eventId 获取状态栏高度
                function getStatusBarHeight() {
                    NativeBridge.getStateBarHeight((data) => {
                        console.log('状态栏高度:', data.height);
                        alert('状态栏高度: ' + data.height + 'px');
                    });
                }
                
                // 示例：使用 eventId 获取 localStorage 值
                function getUserAgreeStatus() {
                    NativeBridge.localStorageGet('userAgree', (data) => {
                        console.log('用户同意状态:', data.key, data.value);
                        alert('用户同意状态: ' + data.value);
                    });
                }
            </script>
        </body>
        </html>
        """
    }
    
    private func initReactNative() {
        // 使用 performSelector 调用 AppDelegate 的 initReactNative 方法
        guard let delegate = appDelegate else {
            print("❌ AppDelegate not set")
            return
        }
        
        let selector = NSSelectorFromString("initReactNative")
        if delegate.responds(to: selector) {
            delegate.perform(selector)
            print("✅ Successfully called initReactNative")
            
            // 关闭当前页面
            DispatchQueue.main.async { [weak self] in
                if let navigationController = self?.navigationController {
                    navigationController.popViewController(animated: true)
                } else {
                    self?.dismiss(animated: true) {
                        print("✅ StartupViewController dismissed")
                    }
                }
            }
        } else {
            print("❌ AppDelegate does not respond to initReactNative")
            print("💡 Make sure initReactNative method is declared as @objc public in AppDelegate")
        }
    }
    
    // 添加回退功能
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 添加手势识别器支持回退
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeGesture.direction = .right
        view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .right {
            goBack()
        }
    }
    
    private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            // 如果没有历史记录，则关闭当前页面
            if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
            } else {
                dismiss(animated: true)
            }
        }
    }
    
    private func localStorageSet(key: String, value: String) {
        let localStorage = UserDefaults.standard
        localStorage.set(value, forKey: key)
        print("localStorageSet: \(key) = \(value)")
    }

    private func localStorageGet(key: String) -> String {
        let localStorage = UserDefaults.standard
        return localStorage.string(forKey: key) ?? ""
    }   

    private func localStorageRemove(key: String) {
        let localStorage = UserDefaults.standard
        localStorage.removeObject(forKey: key)
        print("localStorageRemove: \(key)")
    }

    private func localStorageClear() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        print("localStorageClear")  
    }

    private func getStateBarHeight() -> Int {
        if #available(iOS 13.0, *) {
            // iOS 13+ 使用新的 API
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return Int(windowScene.statusBarManager?.statusBarFrame.height ?? 0)
            }
        }
        // iOS 13 以下使用旧 API
        return Int(UIApplication.shared.statusBarFrame.height)
    }
}