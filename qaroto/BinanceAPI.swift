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
            // Return raw response data as string for error handling
            let errorString = String(data: data, encoding: .utf8) ?? "Invalid response"
            throw BinanceAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            // Return raw error response
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw BinanceAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        do {
            let result = try JSONDecoder().decode(responseType, from: data)
            return result
        } catch {
            // Return raw JSON data for decoding errors
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw BinanceAPIError.decodingError(error, dataString)
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
        
        // Binance /api/v3/account returns an object with balances array
        struct AccountResponse: Codable {
            let balances: [SpotBalance]
        }
        
        let response: AccountResponse = try await performRequest(url: url, headers: headers, responseType: AccountResponse.self)
        
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
    
    // MARK: - Order Management Methods
    
    func createSpotOrder(apiKey: String, secretKey: String, symbol: String, side: String, type: String, quantity: String, price: String?) async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        var query = "symbol=\(symbol)&side=\(side)&type=\(type)&quantity=\(quantity)&timestamp=\(timestamp)"
        
        if let price = price, type == "LIMIT" {
            query += "&price=\(price)&timeInForce=GTC"
        }
        
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(baseURL)/api/v3/order") else {
            throw BinanceAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = finalQuery.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(apiKey: apiKey)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let errorString = String(data: data, encoding: .utf8) ?? "Invalid response"
            throw BinanceAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw BinanceAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        struct OrderResponse: Codable {
            let orderId: Int64
        }
        
        do {
            let orderResponse = try JSONDecoder().decode(OrderResponse.self, from: data)
            return String(orderResponse.orderId)
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw BinanceAPIError.decodingError(error, dataString)
        }
    }
    
    func cancelSpotOrder(apiKey: String, secretKey: String, symbol: String, orderId: String) async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let query = "symbol=\(symbol)&orderId=\(orderId)&timestamp=\(timestamp)"
        let signature = createSignature(query: query, secretKey: secretKey)
        let finalQuery = "\(query)&signature=\(signature)"
        
        guard let url = URL(string: "\(baseURL)/api/v3/order") else {
            throw BinanceAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.httpBody = finalQuery.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let headers = createHeaders(apiKey: apiKey)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let errorString = String(data: data, encoding: .utf8) ?? "Invalid response"
            throw BinanceAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw BinanceAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        struct CancelResponse: Codable {
            let orderId: Int64
            let status: String
        }
        
        do {
            let cancelResponse = try JSONDecoder().decode(CancelResponse.self, from: data)
            return "Order \(cancelResponse.orderId) cancelled with status: \(cancelResponse.status)"
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw BinanceAPIError.decodingError(error, dataString)
        }
    }
}

enum BinanceAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse(String)
    case httpError(Int, String)
    case decodingError(Error, String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse(let raw):
            return "Invalid response: \(raw)"
        case .httpError(let code, let raw):
            return "HTTP Error \(code): \(raw)"
        case .decodingError(let error, let raw):
            return "Decoding error: \(error.localizedDescription). Raw data: \(raw)"
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