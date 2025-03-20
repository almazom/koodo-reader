import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.koodoreader.app',
  appName: 'Koodo Reader',
  webDir: 'build',
  bundledWebRuntime: false,
  server: {
    androidScheme: 'https'
  },
  android: {
    buildOptions: {
      sourceCompatibility: '17',
      targetCompatibility: '17'
    }
  }
};

export default config;
