import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

class BinanceAPI {
    static let shared = BinanceAPI()
    
    private let baseURL = "https://api.binance.com"
    private let futuresBaseURL = "https://fapi.binance.com"
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func createSignature(query: String, secretKey: String) -> String {
        #if canImport(CryptoKit)
        // Use CryptoKit for proper HMAC-SHA256 on iOS
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: query.data(using: .utf8)!, using: key)
        return Data(signature).map { String(format: "%02x", $0) }.joined()
        #else
        // Fallback for non-iOS platforms (testing purposes)
        let combined = secretKey + query
        return combined.sha256()
        #endif
    }
    
    private func createHeaders(apiKey: String) -> [String: String] {
        return ["X-MBX-APIKEY": apiKey]
    }
    
    private func performRequest<T: Codable>(
        url: URL,
        headers: [String: String],
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BinanceAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BinanceAPIError.httpError(httpResponse.statusCode)
        }
        
        do {
            let result = try JSONDecoder().decode(responseType, from: data)
            return result
        } catch {
            throw BinanceAPIError.decodingError(error)
        }
    }
    
    // MARK: - Public API Methods
    
    func getSpotBalance(apiKey: String, secretKey: String) async throws -> [SpotBalance] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(baseURL)/api/v3/account?\(finalQuery)") else {
            throw BinanceAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey)
        let response: SpotBalanceResponse = try await performRequest(url: url, headers: headers, responseType: SpotBalanceResponse.self)
        
        return response.balances.filter { Double($0.free) ?? 0 > 0 || Double($0.locked) ?? 0 > 0 }
    }
    
    func getSpotOpenOrders(apiKey: String, secretKey: String) async throws -> [SpotOrder] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(baseURL)/api/v3/openOrders?\(finalQuery)") else {
            throw BinanceAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey)
        return try await performRequest(url: url, headers: headers, responseType: [SpotOrder].self)
    }
    
    func getContractBalance(apiKey: String, secretKey: String) async throws -> [ContractBalance] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(futuresBaseURL)/fapi/v2/balance?\(finalQuery)") else {
            throw BinanceAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey)
        let balances: [ContractBalance] = try await performRequest(url: url, headers: headers, responseType: [ContractBalance].self)
        
        return balances.filter { Double($0.balance) ?? 0 > 0 }
    }
    
    func getContractPositions(apiKey: String, secretKey: String) async throws -> [ContractPosition] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(futuresBaseURL)/fapi/v2/positionRisk?\(finalQuery)") else {
            throw BinanceAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey)
        let positions: [ContractPosition] = try await performRequest(url: url, headers: headers, responseType: [ContractPosition].self)
        
        return positions.filter { Double($0.positionAmt) ?? 0 != 0 }
    }
    
    func getContractOpenOrders(apiKey: String, secretKey: String) async throws -> [ContractOrder] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(futuresBaseURL)/fapi/v1/openOrders?\(finalQuery)") else {
            throw BinanceAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey)
        return try await performRequest(url: url, headers: headers, responseType: [ContractOrder].self)
    }
}

enum BinanceAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
}

// MARK: - String Extension for SHA256

extension String {
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { bytes in
            // Simple hash for demo purposes - in real app use CryptoKit
            let buffer = bytes.bindMemory(to: UInt8.self)
            for i in 0..<min(buffer.count, 32) {
                hash[i % 32] ^= buffer[i]
            }
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}