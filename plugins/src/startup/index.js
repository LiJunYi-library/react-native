
import expoConfigPlugins from '@expo/config-plugins';
const { withDangerousMod, WarningAggregator } = expoConfigPlugins;
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

export function withCustomAppDelegate(config) {
  console.log('config》〉》〉》〉》〉》', config);
  
  return withDangerousMod(config, [
    'ios',
    async (config) => {
      const filePath = join(
        config.modRequest.platformProjectRoot,
        'expoapp',
        'AppDelegate.swift'
      );

      const templatePath = join(__dirname, '..', '..', 'ios', 'templates', 'AppDelegate.swift');
       console.log('templatePath', templatePath);
       console.log('filePath', filePath);
      // try {
      //   // 检查模板文件是否存在
      //   if (!existsSync(templatePath)) {
      //     throw new Error(`Template AppDelegate.swift not found at: ${templatePath}`);
      //   }

      //   // 读取你的自定义 AppDelegate
      //   const contents = readFileSync(templatePath, 'utf-8');

      //   // 写入到原生项目
      //   writeFileSync(filePath, contents, 'utf-8');

      //   console.log('✅ Successfully replaced AppDelegate.swift');
      // } catch (error) {
      //   WarningAggregator.addWarningIOS(
      //     'withCustomAppDelegate',
      //     `Failed to replace AppDelegate.swift: ${error.message}`
      //   );
      // }

      return config;
    },
  ]);
};