import expoConfigPlugins from "@expo/config-plugins";
const { withDangerousMod, WarningAggregator, withPlugins, withAndroidManifest } = expoConfigPlugins;
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

// 获取当前文件的目录路径（ES6 模块兼容）
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function withStartup(config, options = {}) {
  return withPlugins(config, [
    [withStartupAndroid, options],
    [withStartupIos, options],
  ]);
}

function withStartupAndroid(config, options = {}) {
  return withPlugins(config, [
    withAndroidManifestModifier,
    (config) => withDangerousMod(config, [
      "android",
      async (config) => {
        console.log("开始创建 Android StartActivity.java 文件");

        try {
          // 获取 Android 包名
          const packageName = config.android?.package || "com.anonymous.expoapp";
          console.log("Android 包名:", packageName);

          // 构建目标文件路径
          const packagePath = packageName.replace(/\./g, "/");
          const targetDir = join(
            config.modRequest.platformProjectRoot,
            "app",
            "src",
            "main",
            "java",
            packagePath
          );

          // 确保目录存在
          mkdirSync(targetDir, { recursive: true });

          const targetFilePath = join(targetDir, "StartActivity.java");
          console.log(`目标路径: ${targetFilePath}`);

          // 生成 Java 文件内容
          const contents = createAndroidFileContent(config, options, packageName);

          // 写入文件
          writeFileSync(targetFilePath, contents, "utf-8");

          console.log("✅ Successfully created StartActivity.java");
        } catch (error) {
          console.error("❌ Failed to create StartActivity.java:", error.message);
          WarningAggregator.addWarningAndroid(
            "withStartup",
            `Failed to create StartActivity.java: ${error.message}`
          );
        }

        return config;
      },
    ]),
    (config) => withDangerousMod(config, [
      "android",
      async (config) => {
        console.log("开始覆盖 Android MainApplication.kt 文件");

        try {
          // 获取 Android 包名
          const packageName = config.android?.package || "com.anonymous.expoapp";
          console.log("Android 包名:", packageName);

          // 构建目标文件路径
          const packagePath = packageName.replace(/\./g, "/");
          const targetFilePath = join(
            config.modRequest.platformProjectRoot,
            "app",
            "src",
            "main",
            "java",
            packagePath,
            "MainApplication.kt"
          );

          console.log(`目标路径: ${targetFilePath}`);

          // 读取模板文件内容
          const templatePath = join(__dirname, "android", "templates", "MainApplication.kt");
          let templateContent = readFileSync(templatePath, "utf-8");

          // 替换包名
          templateContent = templateContent.replace(
            /package com\.anonymous\.expoapp/g,
            `package ${packageName}`
          );

          // 写入到原生项目，覆盖原有文件
          writeFileSync(targetFilePath, templateContent, "utf-8");

          console.log("✅ Successfully replaced MainApplication.kt");
        } catch (error) {
          console.error("❌ Failed to replace MainApplication.kt:", error.message);
          WarningAggregator.addWarningAndroid(
            "withStartup",
            `Failed to replace MainApplication.kt: ${error.message}`
          );
        }

        return config;
      },
    ])
  ]);
}

function withAndroidManifestModifier(config) {
  return withAndroidManifest(config, (config) => {
    console.log("开始修改 AndroidManifest.xml");
    
    try {
      const androidManifest = config.modResults;
      
      // 查找 MainActivity
      const mainActivity = androidManifest.manifest.application[0].activity?.find(
        (activity) => activity.$['android:name'] === '.MainActivity'
      );
      
      if (mainActivity) {
        // 移除 MainActivity 的 LAUNCHER intent-filter
        if (mainActivity['intent-filter']) {
          mainActivity['intent-filter'] = mainActivity['intent-filter'].filter(
            (filter) => {
              const hasMainAction = filter.action?.some(
                (action) => action.$['android:name'] === 'android.intent.action.MAIN'
              );
              const hasLauncherCategory = filter.category?.some(
                (category) => category.$['android:name'] === 'android.intent.category.LAUNCHER'
              );
              return !(hasMainAction && hasLauncherCategory);
            }
          );
        }
        
      }
      
      // 添加 StartActivity
      const startActivity = {
        $: {
          'android:name': '.StartActivity',
          'android:configChanges': 'keyboard|keyboardHidden|orientation|screenSize|screenLayout|uiMode',
          'android:exported': 'true'
        },
        'intent-filter': [{
          action: [{
            $: {
              'android:name': 'android.intent.action.MAIN'
            }
          }],
          category: [{
            $: {
              'android:name': 'android.intent.category.LAUNCHER'
            }
          }]
        }]
      };
      
      // 确保 application 数组存在
      if (!androidManifest.manifest.application) {
        androidManifest.manifest.application = [];
      }
      
      // 确保 activity 数组存在
      if (!androidManifest.manifest.application[0].activity) {
        androidManifest.manifest.application[0].activity = [];
      }
      
      // 添加 StartActivity
      androidManifest.manifest.application[0].activity.push(startActivity);
      
      console.log("✅ Successfully modified AndroidManifest.xml");
    } catch (error) {
      console.error("❌ Failed to modify AndroidManifest.xml:", error.message);
      WarningAggregator.addWarningAndroid(
        "withStartup",
        `Failed to modify AndroidManifest.xml: ${error.message}`
      );
    }
    
    return config;
  });
}

function withStartupIos(config, options = {}) {
  return withDangerousMod(config, [
    "ios",
    async (config) => {
      console.log("开始覆盖 AppDelegate.swift 文件");

      // 动态获取 app 名称
      const appName = config.name || "expoapp";
      console.log("App 名称:", appName);

      try {
        const targetFilePath = join(
          config.modRequest.platformProjectRoot,
          appName,
          "AppDelegate.swift"
        );

        console.log(`目标路径: ${targetFilePath}`);

        // 读取模板文件内容
        const contents = getAppDelegateContent(config, options);

        // 写入到原生项目，覆盖原有文件
        writeFileSync(targetFilePath, contents, "utf-8");

        console.log("✅ Successfully replaced AppDelegate.swift");
      } catch (error) {
        console.error("❌ Failed to replace AppDelegate.swift:", error.message);
        WarningAggregator.addWarningIOS(
          "withStartup",
          `Failed to replace AppDelegate.swift: ${error.message}`
        );
      }

      return config;
    },
  ]);
}

function getHtmlFileContent(config = {}, options = {}) {
  let htmlContent = "";
  if (options.customHtmlContent) {
    return options.customHtmlContent.replace(/"/g, '\\"').replace(/\n/g, "\\n");
  }

  if (options.customHtmlUrl) {
    const htmlPath = options.customHtmlUrl;
    if (existsSync(htmlPath)) {
      const htmlFileContent = readFileSync(htmlPath, "utf-8");
      console.log(`从文件读取 HTML 内容: ${htmlPath}`);
      return htmlFileContent.replace(/"/g, '\\"').replace(/\n/g, "\\n");
    } else {
      console.warn(`HTML 文件不存在: ${htmlPath}`);
    }
  }

  const defaultHtmlPath = join(
    config.modRequest.projectRoot,
    "assets",
    "html",
    "privacyAgreement.html"
  );

  if (existsSync(defaultHtmlPath)) {
    const htmlFileContent = readFileSync(defaultHtmlPath, "utf-8");
    htmlContent = htmlFileContent.replace(/"/g, '\\"').replace(/\n/g, "\\n");
    console.log(`使用默认 HTML 文件: ${defaultHtmlPath}`);
  } else {
    console.warn(`默认 HTML 文件不存在: ${defaultHtmlPath}`);
  }
  return htmlContent;
}

function getAppDelegateContent(config = {}, options = {}) {
  let htmlContent = getHtmlFileContent(config, options);
  const moduleName = options.moduleName || "main";
  const limitedModuleName = options.limitedModuleName || "limited";

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
    ${
      htmlContent
        ? `startViewController.setCustomHtmlContent("${htmlContent}")`
        : ""
    }
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
        print("✅ startReactNative withModuleName--: \(moduleName)")
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

function createAndroidFileContent(config, options = {}, packageName) {
  let htmlContent = getHtmlFileContent(config, options);
  const moduleName = options.moduleName || "main";
  const limitedModuleName = options.limitedModuleName || "limited";

  return `package ${packageName};

import com.rainbow.startup.StartupActivity;

public class StartActivity extends StartupActivity {

    @Override
    public String getHtmlUrl() {
        return "";
    }

    @Override
    public String getReactNativeClass() {
        return "${packageName}.MainActivity";
    }

    @Override
    public String getHtmlContent() {
        return "${htmlContent}";
    }
}
  `;
}
