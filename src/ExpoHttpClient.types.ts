/**
 * HTTP リクエストのパラメータ
 */
export type HttpRequestParams = {
  url: string;
  method?: string;
  headers?: Record<string, string>;
  body?: string;
};

/**
 * HTTP レスポンスの内容
 */
export type HttpResponse = {
  status: number;
  statusText: string;
  headers: Record<string, string>;
  body: string;
};

/**
 * Optional: ネイティブモジュールからのイベント（必要に応じて）
 */
export type ExpoHttpClientModuleEvents = {
  onRequestChange?: (params: { value: string }) => void;
};
