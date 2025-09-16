import * as React from 'react';

import { StartupViewProps } from './Startup.types';

export default function StartupView(props: StartupViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
