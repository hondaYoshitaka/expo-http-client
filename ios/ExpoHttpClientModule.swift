import Foundation
import Security
import ExpoModulesCore

struct GenericError: Error, LocalizedError {
  var errorDescription: String?
  init(_ message: String) {
    self.errorDescription = message
  }
}

// クライアント証明書を処理する URLSessionDelegate
class ClientCertificateDelegate: NSObject, URLSessionDelegate {
  func urlSession(_ session: URLSession,
                  didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

    guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate,
          let identity = retrieveClientIdentity() else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)
    completionHandler(.useCredential, credential)
  }

  private func retrieveClientIdentity() -> SecIdentity? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassIdentity,
      kSecReturnRef as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess, let identity = item as! SecIdentity? else {
      print("⚠️ クライアント証明書が見つかりません")
      return nil
    }
    return identity
  }
}

// Expo Modules 用のリクエストパラメータ
struct RequestParams: Record {
  @Field var url: String
  @Field var method: String = "GET"
  @Field var headers: [String: String] = [:]
  @Field var body: String? = nil
}

public class ExpoHttpClientModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoHttpClient")

    AsyncFunction("performRequest") { (params: RequestParams) async throws -> Dictionary<String, Any> in
      guard let requestURL = URL(string: params.url) else {
        throw GenericError("Invalid URL provided: \(params.url)")
      }
      var request = URLRequest(url: requestURL)
      request.httpMethod = params.method

      for (key, value) in params.headers {
        request.addValue(value, forHTTPHeaderField: key)
      }
      if let body = params.body {
        request.httpBody = body.data(using: .utf8)
      }

      let delegate = ClientCertificateDelegate()
      let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

      return try await withCheckedThrowingContinuation { continuation in
        let task = session.dataTask(with: request) { data, response, error in
          if let error = error {
            continuation.resume(throwing: GenericError("Network error: \(error.localizedDescription)"))
            return
          }

          guard let httpResponse = response as? HTTPURLResponse else {
            continuation.resume(throwing: GenericError("Invalid response from server"))
            return
          }
          let headers = httpResponse.allHeaderFields.reduce(into: [String: String]()) { dict, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
              dict[key] = value
            }
          }

          let result: [String: Any] = [
            "status": httpResponse.statusCode,
            "statusText": HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            "headers": headers,
            "body": String(data: data ?? Data(), encoding: .utf8) ?? ""
          ]
          continuation.resume(returning: result)
        }
        task.resume()
      }
    }
  }
}
