import { registerWebModule, NativeModule } from 'expo';

import { StartupModuleEvents } from './Startup.types';

class StartupModule extends NativeModule<StartupModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(StartupModule, 'StartupModule');
