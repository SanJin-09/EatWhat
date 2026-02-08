import Foundation

public enum CoreNetworkingModule {
    public static let name = "CoreNetworking"
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public struct NetworkRequest: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]
    public let headers: [String: String]
    public let body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
    }
}

public enum NetworkError: Error, LocalizedError, Equatable, Sendable {
    case invalidURL
    case nonHTTPResponse
    case serverStatus(code: Int, message: String?)
    case emptyResponse
    case transport(message: String)
    case decoding(message: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请求地址无效。"
        case .nonHTTPResponse:
            return "服务响应格式无效。"
        case .serverStatus(let code, let message):
            if let message, !message.isEmpty {
                return "服务请求失败（\(code)）：\(message)"
            }
            return "服务请求失败（\(code)）。"
        case .emptyResponse:
            return "服务返回为空。"
        case .transport(let message):
            return "网络错误：\(message)"
        case .decoding(let message):
            return "数据解析失败：\(message)"
        }
    }
}

public protocol NetworkClient: Sendable {
    func data(for request: NetworkRequest) async throws -> Data
}

public extension NetworkClient {
    func send<T: Decodable>(
        _ request: NetworkRequest,
        as type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let payload = try await data(for: request)
        do {
            return try decoder.decode(type, from: payload)
        } catch {
            throw NetworkError.decoding(message: error.localizedDescription)
        }
    }
}

public final class URLSessionNetworkClient: NetworkClient, @unchecked Sendable {
    private let baseURL: URL
    private let session: URLSession
    private let defaultHeaders: [String: String]

    public init(
        baseURL: URL,
        session: URLSession = .shared,
        defaultHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.session = session
        self.defaultHeaders = defaultHeaders
    }

    public func data(for request: NetworkRequest) async throws -> Data {
        guard let url = buildURL(path: request.path, queryItems: request.queryItems) else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        for (key, value) in defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.nonHTTPResponse
            }

            guard (200...299).contains(http.statusCode) else {
                let responseMessage = data.isEmpty
                    ? nil
                    : String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw NetworkError.serverStatus(
                    code: http.statusCode,
                    message: responseMessage
                )
            }

            guard !data.isEmpty else {
                throw NetworkError.emptyResponse
            }
            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transport(message: error.localizedDescription)
        }
    }

    private func buildURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let endpoint = baseURL.appendingPathComponent(normalizedPath)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return nil
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url
    }
}
