//
// FKUploadTask.swift
//

import Foundation

public struct FKMultipartField: Sendable {
  public let name: String
  public let data: Data
  public let filename: String?
  public let mimeType: String

  public init(name: String, data: Data, filename: String? = nil, mimeType: String = "application/octet-stream") {
    self.name = name
    self.data = data
    self.filename = filename
    self.mimeType = mimeType
  }

  public static func image(_ image: Data, name: String = "file", filename: String = "image.jpg") -> FKMultipartField {
    FKMultipartField(name: name, data: image, filename: filename, mimeType: "image/jpeg")
  }
}

public extension FKNetworkClient {

  /// Upload multipart/form-data. Progress reported via `onProgress` (0.0–1.0).
  func upload<T: Decodable & Sendable>(
    path: String,
    fields: [FKMultipartField],
    additionalHeaders: [String: String] = [:],
    onProgress: (@Sendable (Double) -> Void)? = nil,
    decoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    let boundary = "FKBoundary.\(UUID().uuidString)"
    let body = buildMultipartBody(fields: fields, boundary: boundary)

    var request = URLRequest(url: try makeURL(path: path))
    request.httpMethod = FKHTTPMethod.post.rawValue
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    configuration.defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }

    let delegate = UploadProgressDelegate(onProgress: onProgress)
    let uploadSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

    let (data, response) = try await uploadSession.upload(for: request, from: body)
    guard let http = response as? HTTPURLResponse else { throw FKNetworkError.noResponse }
    guard (200..<300).contains(http.statusCode) else {
      throw FKNetworkError.httpError(statusCode: http.statusCode, data: data)
    }
    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw FKNetworkError.decodingFailed(error)
    }
  }

  // MARK: - Private

  private func makeURL(path: String) throws -> URL {
    guard let url = URL(string: configuration.baseURL + path) else { throw FKNetworkError.invalidURL }
    return url
  }

  private func buildMultipartBody(fields: [FKMultipartField], boundary: String) -> Data {
    var body = Data()
    let crlf = "\r\n"
    for field in fields {
      body.append("--\(boundary)\(crlf)")
      var disposition = "Content-Disposition: form-data; name=\"\(field.name)\""
      if let filename = field.filename { disposition += "; filename=\"\(filename)\"" }
      body.append("\(disposition)\(crlf)")
      body.append("Content-Type: \(field.mimeType)\(crlf)\(crlf)")
      body.append(field.data)
      body.append(crlf)
    }
    body.append("--\(boundary)--\(crlf)")
    return body
  }
}

// MARK: - Progress delegate

private final class UploadProgressDelegate: NSObject, URLSessionTaskDelegate, Sendable {
  private let onProgress: (@Sendable (Double) -> Void)?
  init(onProgress: (@Sendable (Double) -> Void)?) { self.onProgress = onProgress }

  func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    guard totalBytesExpectedToSend > 0 else { return }
    onProgress?(Double(totalBytesSent) / Double(totalBytesExpectedToSend))
  }
}

private extension Data {
  mutating func append(_ string: String) {
    if let data = string.data(using: .utf8) { append(data) }
  }
}
