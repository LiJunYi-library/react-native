// Reexport the native module. On web, it will be resolved to StartupModule.web.ts
// and on native platforms to StartupModule.ts
export { default } from './StartupModule';
export { default as StartupView } from './StartupView';
export * from  './Startup.types';
