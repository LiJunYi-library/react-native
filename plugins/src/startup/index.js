
import expoConfigPlugins from '@expo/config-plugins';
const { withDangerousMod, WarningAggregator, withXcodeProject } = expoConfigPlugins;
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

// 获取当前文件的目录路径
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function withCustomAppDelegate(config) {
  console.log('处理自定义AppDelegate');
  
  // 先复制文件
  const configWithFiles = withDangerousMod(config, ['ios', async (config) => {
    console.log('开始处理 iOS 文件复制');
    
    // 动态获取 app 名称
    const appName = config.name || 'expoapp';
    console.log('App 名称:', appName);
    
    try {
      // 需要复制的文件列表
      const filesToCopy = [
        'AppDelegate.swift',
        'StartViewController.swift', 
        'WebViewController.swift'
      ];

      for (const fileName of filesToCopy) {
        const templateFilePath = join(__dirname, 'ios', 'templates', fileName);
        const targetFilePath = join(
          config.modRequest.platformProjectRoot,
          appName,
          fileName
        );

        console.log(`处理文件: ${fileName}`);
        console.log(`模板路径: ${templateFilePath}`);
        console.log(`目标路径: ${targetFilePath}`);

        // 检查模板文件是否存在
        if (!existsSync(templateFilePath)) {
          throw new Error(`Template ${fileName} not found at: ${templateFilePath}`);
        }

        // 读取模板文件内容
        const contents = readFileSync(templateFilePath, 'utf-8');

        // 写入到原生项目
        writeFileSync(targetFilePath, contents, 'utf-8');

        console.log(`✅ Successfully copied ${fileName}`);
      }

      console.log('✅ All template files copied successfully');
    } catch (error) {
      console.error('❌ Failed to copy template files:', error.message);
      WarningAggregator.addWarningIOS(
        'withCustomAppDelegate',
        `Failed to copy template files: ${error.message}`
      );
    }

    return config;
  }]);

  // 自动更新 Xcode 项目文件
  return withXcodeProject(configWithFiles, (config) => {
    console.log('开始自动更新 Xcode 项目文件');
    
    const xcodeProject = config.modResults;
    const appName = config.name || 'expoapp';
    
    // 需要添加到 Xcode 项目的文件列表
    const filesToAdd = [
      'StartViewController.swift',
      'WebViewController.swift'
    ];

    for (const fileName of filesToAdd) {
      try {
        // 直接修改项目文件，跳过 xcodeProject.addSourceFile
        const projectPath = join(config.modRequest.platformProjectRoot, `${appName}.xcodeproj`, 'project.pbxproj');
        let projectContent = readFileSync(projectPath, 'utf-8');
        
        // 检查文件是否已经在项目中
        if (!projectContent.includes(fileName)) {
          // 生成唯一的 UUID
          const generateUUID = () => {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
              const r = Math.random() * 16 | 0;
              const v = c == 'x' ? r : (r & 0x3 | 0x8);
              return v.toString(16);
            }).toUpperCase();
          };
          
          const fileRefUUID = generateUUID();
          const buildFileUUID = generateUUID();
          
          // 添加文件引用到 PBXFileReference section
          const fileRef = `\t\t${fileRefUUID} /* ${fileName} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = "${fileName}"; path = "${appName}/${fileName}"; sourceTree = "<group>"; };`;
          projectContent = projectContent.replace(
            /(\/\* End PBXFileReference section \*\/)/,
            `$1\n${fileRef}`
          );
          
          // 添加构建文件到 PBXBuildFile section
          const buildFile = `\t\t${buildFileUUID} /* ${fileName} in Sources */ = {isa = PBXBuildFile; fileRef = ${fileRefUUID} /* ${fileName} */; };`;
          projectContent = projectContent.replace(
            /(\/\* End PBXBuildFile section \*\/)/,
            `$1\n${buildFile}`
          );
          
          // 添加文件到 expoapp group
          const groupRef = `\t\t\t\t${fileRefUUID} /* ${fileName} */,`;
          projectContent = projectContent.replace(
            /(\t\t\t\tF11748412D0307B40044C1D9 \/\* AppDelegate\.swift \*\/,)/,
            `$1\n${groupRef}`
          );
          
          // 添加文件到 Sources build phase
          const sourcesRef = `\t\t\t\t${buildFileUUID} /* ${fileName} in Sources */,`;
          projectContent = projectContent.replace(
            /(\t\t\t\tF11748422D0307B40044C1D9 \/\* AppDelegate\.swift in Sources \*\/,)/,
            `$1\n${sourcesRef}`
          );
          
          writeFileSync(projectPath, projectContent, 'utf-8');
          console.log(`✅ 通过修改项目文件添加 ${fileName}`);
        } else {
          console.log(`ℹ️ ${fileName} 已存在于 Xcode 项目中`);
        }
      } catch (error) {
        console.error(`❌ 添加 ${fileName} 到 Xcode 项目失败:`, error.message);
      }
    }

    console.log('✅ Xcode 项目文件更新完成');
    return config;
  });
}