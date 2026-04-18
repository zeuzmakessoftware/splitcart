import Foundation

enum ReceiptScannerClientError: LocalizedError {
    case invalidResponse
    case server(String)
    case invalidPayload

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The receipt service returned an unreadable response."
        case let .server(message):
            return message
        case .invalidPayload:
            return "The receipt image could not be prepared for upload."
        }
    }
}

struct ReceiptScannerClient {
    var baseURL = URL(string: "http://127.0.0.1:8000")!

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func scanReceipt(
        imageData: Data,
        payload: ReceiptScanRequestPayload,
        fileName: String = "receipt.jpg"
    ) async throws -> ReceiptScanResponse {
        guard !imageData.isEmpty else {
            throw ReceiptScannerClientError.invalidPayload
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("scan-and-split"))
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let payloadString = try String(
            decoding: encoder.encode(payload),
            as: UTF8.self
        )

        request.httpBody = multipartBody(
            boundary: boundary,
            payload: payloadString,
            imageData: imageData,
            fileName: fileName
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReceiptScannerClientError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "The backend returned \(httpResponse.statusCode)."
            throw ReceiptScannerClientError.server(message)
        }

        return try decoder.decode(ReceiptScanResponse.self, from: data)
    }

    private func multipartBody(
        boundary: String,
        payload: String,
        imageData: Data,
        fileName: String
    ) -> Data {
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"payload\"\r\n\r\n")
        body.append("\(payload)\r\n")

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(string.data(using: .utf8)!)
    }
}
