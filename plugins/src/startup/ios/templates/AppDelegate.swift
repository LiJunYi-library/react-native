import Expo
import React
import ReactAppDependencyProvider
import Startup

@UIApplicationMain
public class AppDelegate: ExpoAppDelegate {
  var window: UIWindow?
  var navigationController: UINavigationController?

  var reactNativeDelegate: ExpoReactNativeFactoryDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  public override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // 保存 launchOptions 供后续使用
    self.launchOptions = launchOptions
    
    // 检查用户是否已经同意
    let localStorage = UserDefaults.standard
    let userAgree = localStorage.string(forKey: "userAgree")
    print("用户同意隐私协议：\(userAgree ?? "nil")")
    
    if userAgree == "true" {
      initAgreeSdks();
      initReactNativeFactory(launchOptions: launchOptions)
    } else if userAgree == "false" {
      initNotAgreeSdks();
      initReactNativeFactory(launchOptions: launchOptions)
    } else {
      initStartupViewController()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func initStartupViewController() {
    window = UIWindow(frame: UIScreen.main.bounds)
    let startViewController = StartupViewController()
    startViewController.setAppDelegate(self)
    navigationController = UINavigationController(rootViewController: startViewController)
    navigationController?.isNavigationBarHidden = true 
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()
  }

  @objc public func initReactNativeFactory(launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {
    let delegate = ReactNativeDelegate()
    let factory = ExpoReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()
    reactNativeDelegate = delegate
    reactNativeFactory = factory
    bindReactNativeFactory(factory)

    #if os(iOS) || os(tvOS)
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let userAgree = UserDefaults.standard.string(forKey: "userAgree")
        let moduleName = (userAgree == "true") ? "main" : "limited"
        
        factory.startReactNative(
          withModuleName: moduleName,
          in: window,
          launchOptions: launchOptions)
    #endif
  }
  
  // 专门为 performSelector 调用的无参数方法
  @objc public func initReactNative() {
    // 尝试获取当前的 launchOptions，如果没有则使用 nil
    let currentLaunchOptions = self.launchOptions ?? nil
    initReactNativeFactory(launchOptions: currentLaunchOptions)
  }
  
  // 存储原始的 launchOptions
  private var launchOptions: [UIApplication.LaunchOptionsKey: Any]?

  // Linking API
  public override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options) || RCTLinkingManager.application(app, open: url, options: options)
  }

  // Universal Links
  public override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let result = RCTLinkingManager.application(application, continue: userActivity, restorationHandler: restorationHandler)
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler) || result
  }

  func initAgreeSdks(){

  }

  func initNotAgreeSdks(){

  }
}

class ReactNativeDelegate: ExpoReactNativeFactoryDelegate {
  // Extension point for config-plugins

  override func sourceURL(for bridge: RCTBridge) -> URL? {
    // needed to return the correct URL for expo-dev-client.
    bridge.bundleURL ?? bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    return RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: ".expo/.virtual-metro-entry")
#else
    return Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
