
import expoConfigPlugins from '@expo/config-plugins';
const { withDangerousMod, WarningAggregator } = expoConfigPlugins;
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// 获取当前文件的目录路径
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function withCustomAppDelegate(config) {
  console.log('处理自定义AppDelegate');
  
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
      const contents = readFileSync(templateFilePath, 'utf-8');

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