import UIKit
import WebKit

public class WebViewController: UIViewController {
    
    var urlString: String = ""
    private var webView: WKWebView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupNavigationBar()
        loadURL()
    }
    
    private func setupWebView() {
        // 创建WebView配置
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        // 设置WebView约束，撑满整个页面
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        // 设置导航栏标题
        title = "网页浏览"
        
        // 添加返回按钮
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // 添加刷新按钮
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem = refreshButton
    }
    
    private func loadURL() {
        guard let url = URL(string: urlString) else {
            showErrorAlert(message: "无效的URL地址")
            return
        }
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc private func backButtonTapped() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            // 如果是模态呈现的，使用dismiss关闭
            if presentingViewController != nil {
                dismiss(animated: true)
            } else {
                navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc private func refreshButtonTapped() {
        webView.reload()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 开始加载时显示加载指示器
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 加载完成时隐藏加载指示器
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        title = webView.title ?? "网页浏览"
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 加载失败时隐藏加载指示器并显示错误
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        showErrorAlert(message: "网页加载失败: \(error.localizedDescription)")
    }
}
