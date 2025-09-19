package com.rainbow.startup;

import android.annotation.SuppressLint;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.os.Build;
import android.widget.Toast;

import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;

import java.util.Set;

public class StartupActivity extends AppCompatActivity {
    Application app;
    WebView webView;

    public class WebAppInterface {
        Context mContext;

        WebAppInterface(Context c) {
            mContext = c;
        }

        @JavascriptInterface
        public void exitApp() {
            StartupActivity.this.exitApp();
        }

        @JavascriptInterface
        public void openWeb(String url) {
            StartupActivity.this.openWeb(url);
        }

        @JavascriptInterface
        public void initReactNative() {
            StartupActivity.this.initReactNative();
        }

        @JavascriptInterface
        public void localStorageSet(String key, String value) {
            StartupActivity.this.localStorageSet(key, value);
        }

        @JavascriptInterface
        public String localStorageGet(String key) {
            return StartupActivity.this.localStorageGet(key);
        }

        @JavascriptInterface
        public void localStorageRemove(String key) {
            StartupActivity.this.localStorageRemove(key);
        }

        @JavascriptInterface
        public void localStorageClear() {
            StartupActivity.this.localStorageClear();
        }

        @JavascriptInterface
        public int getStateBarHeight() {
            return StartupActivity.this.getStateBarHeight();
        }
    }

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setupFullscreen();
        init();
    }

    private void setupFullscreen() {
        try {
            Log.d("StartupActivity", "Setting up transparent status bar");

            // 设置状态栏为透明
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Android 5.0 及以上版本
                getWindow().setStatusBarColor(android.graphics.Color.TRANSPARENT);
                getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
            }

            // 保持屏幕常亮
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            Log.d("StartupActivity", "Transparent status bar setup completed successfully");

        } catch (Exception e) {
            Log.e("StartupActivity", "Error setting up transparent status bar", e);
        }
    }

    @Override
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) {
            webView.goBack();
        } else {
            // 否则执行默认的回退行为
            super.onBackPressed();
        }
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.clearHistory();
            webView.destroy();
            webView = null;
        }
        super.onDestroy();
    }

    protected void init() {
        String userAgree = getSharedPreferences("text", MODE_PRIVATE).getString("userAgree", "");
        app = getApplication();
        Log.d(">>>>>> StartupActivity init", ":" + userAgree);
        if ("true".equals(userAgree) || "false".equals(userAgree)) {
            Log.d(">>>>>> 直接启动react native 页面", userAgree);
            startMainActivity();
            return;
        }
        setWebViewContent();
    }

    protected String getHtmlContent() {
        return "";
    }

    protected String getHtmlUrl() {
        return "";
    }

    protected String getReactNativeClass() {
        return "";
    }

    @SuppressLint("SetJavaScriptEnabled")
    public void setWebViewContent() {
        webView = new WebView(this);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.canGoBack();
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    // API 21+ 使用新方法
                    view.loadUrl(request.getUrl().toString());
                    return true;
                }
                return false;
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                // API 21 以下使用旧方法
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
                    view.loadUrl(url);
                    return true;
                }
                return false;
            }
        });
        webView.addJavascriptInterface(new WebAppInterface(this), "NativeBridge");

        // 检查是否有远程 URL，如果有则加载远程 HTML，否则加载本地内容
        String htmlUrl = getHtmlUrl();
        String htmlContent = getHtmlContent();

        if (htmlUrl != null && !htmlUrl.trim().isEmpty()) {
            // 有远程 URL，加载远程 HTML
            Log.d("StartupActivity", "Loading remote URL: " + htmlUrl);
            webView.loadUrl(htmlUrl);
        } else if (htmlContent != null && !htmlContent.trim().isEmpty()) {
            // 没有远程 URL 但有本地内容，加载本地 HTML
            Log.d("StartupActivity", "Loading local HTML content");
            webView.loadDataWithBaseURL(null, htmlContent, "text/html", "UTF-8", null);
        } else {
            // 都没有，加载默认内容
            Log.d("StartupActivity", "Loading default content");
            webView.loadDataWithBaseURL(null, "<html><body><h1>No content available</h1></body></html>", "text/html", "UTF-8", null);
        }

        setContentView(webView);
    }

    public void startMainActivity() {
        Intent startIntent = getIntent();
        Intent intent = null;
        try {
            String reactNativeClass = getReactNativeClass();
            if (reactNativeClass != null && !reactNativeClass.trim().isEmpty()) {
                Class<?> activityClass = Class.forName(reactNativeClass);
                intent = new Intent(StartupActivity.this, activityClass);
                Set<String> startCategories = startIntent.getCategories();
                if (startCategories != null) {
                    for (String categories : startCategories) {
                        intent.addCategory(categories);
                    }
                }
                if (startIntent.getAction() != null) intent.setAction(startIntent.getAction());
                if (startIntent.getData() != null) intent.setData(startIntent.getData());
                startActivity(intent);
                finish();
            }
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    public void exitApp() {
        finishAffinity();
        System.exit(0);
    }

    public void openWeb(String url) {
        // Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        // startActivity(intent);
    }

    public void initReactNative() {
        try {
            if (app != null) {
                Class<?> appClass = app.getClass();
                java.lang.reflect.Method initMethod = appClass.getMethod("initReactNative");
                initMethod.invoke(app);
                Toast.makeText(this, "React Native初始化成功", Toast.LENGTH_SHORT).show();
                startMainActivity();
            } else {
                Toast.makeText(this, "Application实例为空", Toast.LENGTH_SHORT).show();
            }
        } catch (Exception e) {
            e.printStackTrace();
            Toast.makeText(this, "React Native初始化失败: " + e.getMessage(), Toast.LENGTH_SHORT).show();
        }
    }

    public void localStorageSet(String key, String value) {
        getSharedPreferences("text", MODE_PRIVATE).edit().putString(key, value).apply();
    }

    public String localStorageGet(String key) {
        return getSharedPreferences("text", MODE_PRIVATE).getString(key, "");
    }

    public void localStorageRemove(String key) {
        getSharedPreferences("text", MODE_PRIVATE).edit().remove(key).apply();
    }

    public void localStorageClear() {
        getSharedPreferences("text", MODE_PRIVATE).edit().clear().apply();
    }

    public int getStateBarHeight() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11 (API 30) 及以上版本使用 WindowInsets
            WindowInsets windowInsets = getWindow().getDecorView().getRootWindowInsets();
            if (windowInsets != null) {
                return windowInsets.getInsets(WindowInsets.Type.statusBars()).top;
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6.0 (API 23) 到 Android 10 (API 29) 使用 WindowInsets
            View decorView = getWindow().getDecorView();
            WindowInsets windowInsets = decorView.getRootWindowInsets();
            if (windowInsets != null) {
                return windowInsets.getSystemWindowInsetTop();
            }
        }

        // 如果上述方法都不可用，使用反射获取状态栏高度
        try {
            Class<?> clazz = Class.forName("com.android.internal.R$dimen");
            Object object = clazz.newInstance();
            int height = Integer.parseInt(clazz.getField("status_bar_height").get(object).toString());
            return getResources().getDimensionPixelSize(height);
        } catch (Exception e) {
            Log.e("StartupActivity", "Failed to get status bar height", e);
            // 返回默认值
            return (int) (24 * getResources().getDisplayMetrics().density);
        }
    }

}