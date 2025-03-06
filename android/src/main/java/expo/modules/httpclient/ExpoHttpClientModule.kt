package com.example.expohttpclient

import android.security.KeyChain
import android.security.KeyChainException
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import okhttp3.*
import java.security.KeyStore
import java.security.cert.Certificate
import javax.net.ssl.*

class RequestParams : Record {
  @Field var url: String = ""
  @Field var method: String = "GET"
  @Field var headers: Map<String, String> = emptyMap()
  @Field var body: String? = null
}

class HttpResponse : Record {
  var status: Int = 0
  var statusText: String = ""
  var headers: Map<String, String> = emptyMap()
  var body: String = ""

  constructor(status: Int, statusText: String, headers: Map<String, String>, body: String) {
    this.status = status
    this.statusText = statusText
    this.headers = headers
    this.body = body
  }
}

class ExpoHttpClientModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoHttpClient")

    AsyncFunction("performRequest") { params: RequestParams ->
      return@AsyncFunction performHttpRequest(params)
    }
  }

  private fun getSSLSocketFactory(): SSLSocketFactory? {
    return try {
      val keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm())
      val keyStore = KeyStore.getInstance("AndroidKeyStore")
      keyStore.load(null)

      keyManagerFactory.init(keyStore, null)

      val sslContext = SSLContext.getInstance("TLS")
      sslContext.init(keyManagerFactory.keyManagers, null, null)
      sslContext.socketFactory
    } catch (e: Exception) {
      e.printStackTrace()
      null
    }
  }

  private suspend fun performHttpRequest(params: RequestParams): HttpResponse {
    val sslSocketFactory = getSSLSocketFactory() ?: throw Exception("Failed to load SSL Context")

    val client = OkHttpClient.Builder()
      .sslSocketFactory(sslSocketFactory, TrustAllCerts())
      .build()

    val request = Request.Builder()
      .url(params.url)
      .build()

    val response = client.newCall(request).execute()
    return HttpResponse(response.code(), response.message(), response.headers().toMultimap(), response.body()?.string() ?: "")
  }
}
