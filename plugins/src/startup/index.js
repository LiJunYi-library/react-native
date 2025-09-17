
import expoConfigPlugins from '@expo/config-plugins';
const { withDangerousMod, WarningAggregator } = expoConfigPlugins;
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// 获取当前文件的目录路径
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function withCustomAppDelegate(config, options = {}) {
  console.log('处理自定义AppDelegate');
  console.log('插件选项:', options);
  
  return withDangerousMod(config, ['ios', async (config) => {
    console.log('开始覆盖 AppDelegate.swift 文件');
    
    // 动态获取 app 名称
    const appName = config.name || 'expoapp';
    console.log('App 名称:', appName);
    
    try {
      const templateFilePath = join(__dirname, 'ios', 'templates', 'AppDelegate.swift');
      const targetFilePath = join(
        config.modRequest.platformProjectRoot,
        appName,
        'AppDelegate.swift'
      );

      console.log(`模板路径: ${templateFilePath}`);
      console.log(`目标路径: ${targetFilePath}`);

      // 检查模板文件是否存在
      if (!existsSync(templateFilePath)) {
        throw new Error(`Template AppDelegate.swift not found at: ${templateFilePath}`);
      }

      // 读取模板文件内容
      const contents = getAppDelegateContent(config, options)

      // 写入到原生项目，覆盖原有文件
      writeFileSync(targetFilePath, contents, 'utf-8');

      console.log('✅ Successfully replaced AppDelegate.swift');
    } catch (error) {
      console.error('❌ Failed to replace AppDelegate.swift:', error.message);
      WarningAggregator.addWarningIOS(
        'withCustomAppDelegate',
        `Failed to replace AppDelegate.swift: ${error.message}`
      );
    }

    return config;
  }]);
}

function getAppDelegateContent(config = {}, options = {}) {
  // 处理 HTML 内容
  let htmlContent = '';
  
  if (options.customHtmlContent) {
    // 直接使用传入的 HTML 内容
    htmlContent = options.customHtmlContent.replace(/"/g, '\\"').replace(/\n/g, '\\n');
    console.log('使用自定义 HTML 内容');
  } else if (options.customHtmlUrl) {
    // 从指定路径读取 HTML 文件
    const htmlPath = options.customHtmlUrl;
    if (existsSync(htmlPath)) {
      const htmlFileContent = readFileSync(htmlPath, 'utf-8');
      htmlContent = htmlFileContent.replace(/"/g, '\\"').replace(/\n/g, '\\n');
      console.log(`从文件读取 HTML 内容: ${htmlPath}`);
    } else {
      console.warn(`HTML 文件不存在: ${htmlPath}`);
    }
  } else {
    // 使用默认的 HTML 文件路径
    const defaultHtmlPath = join(config.modRequest.projectRoot, 'assets', 'html', 'privacyAgreement.html');
    if (existsSync(defaultHtmlPath)) {
      const htmlFileContent = readFileSync(defaultHtmlPath, 'utf-8');
      htmlContent = htmlFileContent.replace(/"/g, '\\"').replace(/\n/g, '\\n');
      console.log(`使用默认 HTML 文件: ${defaultHtmlPath}`);
    } else {
      console.warn(`默认 HTML 文件不存在: ${defaultHtmlPath}`);
    }
  }

  const moduleName = options.moduleName || 'main';

  const limitedModuleName = options.limitedModuleName || 'limited';


  return `
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
    ${htmlContent ? `startViewController.setCustomHtmlContent("${htmlContent}")` : ''}
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
        let moduleName = (userAgree == "true") ? "${moduleName}" : "${limitedModuleName}"
        print("✅ startReactNative withModuleName: \(moduleName)")
        print(moduleName)
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

  `;
}