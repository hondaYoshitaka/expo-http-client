import { NativeModule, requireNativeModule } from 'expo-modules-core';
import type { HttpRequestParams, HttpResponse, ExpoHttpClientModuleEvents } from './ExpoHttpClient.types';

declare class ExpoHttpClientModule extends NativeModule<ExpoHttpClientModuleEvents> {
  /**
   * mTLS を利用した HTTP リクエストを実行します。
   * @param request - HTTP リクエストの詳細パラメータ
   * @returns レスポンス内容（HTTP ステータス、ヘッダー、ボディ）
   */
  performRequest(request: HttpRequestParams): Promise<HttpResponse>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoHttpClientModule>('ExpoHttpClient');
