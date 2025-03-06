// Reexport the native module. On web, it will be resolved to ExpoHttpClientModule.web.ts
// and on native platforms to ExpoHttpClientModule.ts
export { default } from './ExpoHttpClientModule';
export * from  './ExpoHttpClient.types';
