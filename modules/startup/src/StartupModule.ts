import { NativeModule, requireNativeModule } from 'expo';

import { StartupModuleEvents } from './Startup.types';

declare class StartupModule extends NativeModule<StartupModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<StartupModule>('Startup');
