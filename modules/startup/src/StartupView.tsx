import { requireNativeView } from 'expo';
import * as React from 'react';

import { StartupViewProps } from './Startup.types';

const NativeView: React.ComponentType<StartupViewProps> =
  requireNativeView('Startup');

export default function StartupView(props: StartupViewProps) {
  return <NativeView {...props} />;
}
