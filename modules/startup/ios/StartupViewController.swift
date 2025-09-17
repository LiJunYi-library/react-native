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
        view.backgroundColor = .white
        showCustomAlert()
    }
    
    // MARK: - Private Methods
    private func showCustomAlert() {
        // 创建半透明背景
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.frame = view.bounds
        view.addSubview(overlay)
        
        // 弹窗宽度 = 屏宽 - 40 (左右各20)
        let screenWidth = view.bounds.width
        let popupWidth = screenWidth - 2 * margin
        let popupHeight = view.bounds.height * 0.6
        
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.layer.cornerRadius = 12
        popupView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到 overlay（防止被键盘顶起）
        overlay.addSubview(popupView)
        
        // Auto Layout
        NSLayoutConstraint.activate([
            popupView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            popupView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            popupView.widthAnchor.constraint(equalToConstant: popupWidth),
            popupView.heightAnchor.constraint(equalToConstant: popupHeight)
        ])
        
        // 创建 WKWebView
        let webConfiguration = WKWebViewConfiguration()
        
        // 设置 message handler，用于 JS 调用原生
        webConfiguration.userContentController.add(self, name: "exitApp")
        webConfiguration.userContentController.add(self, name: "openWeb")
        webConfiguration.userContentController.add(self, name: "initReactNative")
        webConfiguration.userContentController.add(self, name: "localStorageSet")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        popupView.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: popupView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor)
        ])
        
        // 加载 HTML 字符串（使用自定义内容或默认内容）
        let htmlContent = customHtmlContent ?? getDefaultHtmlContent()
        
        let injectedScript = """
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
            <button onclick="nativeOpenWeb()">打开网页</button>
            <button onclick="nativeInitReactNative()">初始化 RN</button>

            <script>
                // 封装 JS 调用原生的方法
                function nativeExitApp() {
                    NativeBridge.exitApp()
                }
                
                function nativeOpenWeb() {
                    const url = 'https://expo.dev';
                    NativeBridge.openWeb(url)
                }
                
                function nativeInitReactNative() {
                    NativeBridge.localStorageSet('userAgree', 'true')
                    NativeBridge.initReactNative()
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
                self?.dismiss(animated: true) {
                    print("✅ StartupViewController dismissed")
                }
            }
        } else {
            print("❌ AppDelegate does not respond to initReactNative")
            print("💡 Make sure initReactNative method is declared as @objc public in AppDelegate")
        }
    }
    
    private func localStorageSet(key: String, value: String) {
        let localStorage = UserDefaults.standard
        localStorage.set(value, forKey: key)
        print("localStorageSet: \(key) = \(value)")
    }
}