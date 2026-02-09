import Foundation
import UIKit

struct ServerResponse {
    let token: String?
    let location: String?
    let hasSeparator: Bool
}

final class NetworkService {
    static let shared = NetworkService()
    
    private let baseAddress = "https://aprulestext.site/ios-circlehit-shootsmash/server.php"
    private let paramP = "Bs2675kDjkb5Ga"
    
    private init() {}
    
    func fetchLaunchPayload() async throws -> ServerResponse {
        var components = URLComponents(string: baseAddress)!
        components.queryItems = [
            URLQueryItem(name: "p", value: paramP),
            URLQueryItem(name: "os", value: DeviceInfo.systemVersion),
            URLQueryItem(name: "lng", value: DeviceInfo.languageCode),
            URLQueryItem(name: "devicemodel", value: DeviceInfo.modelIdentifier),
            URLQueryItem(name: "country", value: DeviceInfo.countryCode)
        ]
        guard let requestAddress = components.url else {
            throw NSError(domain: "NetworkService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid request address"])
        }
        var request = URLRequest(url: requestAddress)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpShouldUsePipelining = false
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("no-cache", forHTTPHeaderField: "Pragma")
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        let session = URLSession(configuration: config)
        let (data, _) = try await session.data(for: request)
        let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let idx = raw.firstIndex(of: "#") {
            let tokenPart = String(raw[..<idx]).trimmingCharacters(in: .whitespacesAndNewlines)
            let locationPart = String(raw[raw.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return ServerResponse(token: tokenPart.isEmpty ? nil : tokenPart, location: locationPart.isEmpty ? nil : locationPart, hasSeparator: true)
        }
        return ServerResponse(token: nil, location: nil, hasSeparator: false)
    }
}
