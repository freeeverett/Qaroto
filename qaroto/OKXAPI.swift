import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

class OKXAPI {
    static let shared = OKXAPI()
    
    private let baseURL = "https://www.okx.com"
    
    private init() {}
    
    // MARK: - Helper Methods
    
    private func createSignature(timestamp: String, method: String, requestPath: String, body: String, secretKey: String) -> String {
        #if canImport(CryptoKit)
        let message = timestamp + method + requestPath + body
        let key = SymmetricKey(data: secretKey.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: message.data(using: .utf8)!, using: key)
        return Data(signature).base64EncodedString()
        #else
        // Fallback for non-iOS platforms
        let message = timestamp + method + requestPath + body
        let combined = secretKey + message
        return combined.sha256()
        #endif
    }
    
    private func createHeaders(apiKey: String, secretKey: String, passphrase: String, timestamp: String, method: String, requestPath: String, body: String = "") -> [String: String] {
        let signature = createSignature(timestamp: timestamp, method: method, requestPath: requestPath, body: body, secretKey: secretKey)
        
        return [
            "OK-ACCESS-KEY": apiKey,
            "OK-ACCESS-SIGN": signature,
            "OK-ACCESS-TIMESTAMP": timestamp,
            "OK-ACCESS-PASSPHRASE": passphrase,
            "Content-Type": "application/json"
        ]
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
            throw OKXAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            // Return raw error response
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw OKXAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        do {
            let result = try JSONDecoder().decode(responseType, from: data)
            return result
        } catch {
            // Return raw JSON data for decoding errors
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw OKXAPIError.decodingError(error, dataString)
        }
    }
    
    // MARK: - Public API Methods
    
    func getSpotBalance(apiKey: String, secretKey: String, passphrase: String) async throws -> [SpotBalance] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/account/balance"
        
        guard let url = URL(string: "\(baseURL)\(requestPath)") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "GET", requestPath: requestPath)
        let response: OKXBalanceResponse = try await performRequest(url: url, headers: headers, responseType: OKXBalanceResponse.self)
        
        return response.data.flatMap { $0.details }.compactMap { detail in
            guard (Double(detail.availBal) ?? 0) > 0 || (Double(detail.frozenBal) ?? 0) > 0 else { return nil }
            return SpotBalance(asset: detail.ccy, free: detail.availBal, locked: detail.frozenBal)
        }
    }
    
    func getSpotOpenOrders(apiKey: String, secretKey: String, passphrase: String) async throws -> [SpotOrder] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/trade/orders-pending"
        
        guard let url = URL(string: "\(baseURL)\(requestPath)?instType=SPOT") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "GET", requestPath: requestPath + "?instType=SPOT")
        let response: OKXOrderResponse = try await performRequest(url: url, headers: headers, responseType: OKXOrderResponse.self)
        
        return response.data.map { order in
            SpotOrder(
                symbol: order.instId,
                orderId: Int64(order.ordId) ?? 0,
                orderListId: -1,
                clientOrderId: order.clOrdId ?? "",
                price: order.px,
                origQty: order.sz,
                executedQty: order.fillSz,
                cummulativeQuoteQty: order.fillNotionalUsd,
                status: order.state,
                timeInForce: order.tgtCcy,
                type: order.ordType,
                side: order.side.uppercased(),
                stopPrice: "0",
                icebergQty: "0",
                time: Int64(order.cTime) ?? 0,
                updateTime: Int64(order.uTime) ?? 0,
                isWorking: true,
                origQuoteOrderQty: order.notionalUsd
            )
        }
    }
    
    func getContractBalance(apiKey: String, secretKey: String, passphrase: String) async throws -> [ContractBalance] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/account/balance"
        
        guard let url = URL(string: "\(baseURL)\(requestPath)") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "GET", requestPath: requestPath)
        let response: OKXBalanceResponse = try await performRequest(url: url, headers: headers, responseType: OKXBalanceResponse.self)
        
        return response.data.flatMap { $0.details }.compactMap { detail in
            guard (Double(detail.availBal) ?? 0) > 0 else { return nil }
            return ContractBalance(
                accountAlias: nil,
                asset: detail.ccy,
                balance: detail.bal,
                crossWalletBalance: detail.availBal,
                crossUnPnl: detail.upl,
                availableBalance: detail.availBal,
                maxWithdrawAmount: detail.availBal,
                marginAvailable: true,
                updateTime: Int64(Date().timeIntervalSince1970 * 1000)
            )
        }
    }
    
    func getContractPositions(apiKey: String, secretKey: String, passphrase: String) async throws -> [ContractPosition] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/account/positions"
        
        guard let url = URL(string: "\(baseURL)\(requestPath)") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "GET", requestPath: requestPath)
        let response: OKXPositionResponse = try await performRequest(url: url, headers: headers, responseType: OKXPositionResponse.self)
        
        return response.data.compactMap { position in
            guard (Double(position.pos) ?? 0) != 0 else { return nil }
            return ContractPosition(
                symbol: position.instId,
                initialMargin: position.imr,
                maintMargin: position.mmr,
                unrealizedProfit: position.upl,
                positionInitialMargin: position.imr,
                openOrderInitialMargin: "0",
                leverage: position.lever,
                isolated: position.mgnMode == "isolated",
                entryPrice: position.avgPx,
                maxNotional: position.notionalUsd,
                positionSide: position.posSide.uppercased(),
                positionAmt: position.pos,
                notional: position.notionalUsd,
                isolatedWallet: position.margin,
                updateTime: Int64(position.uTime) ?? 0
            )
        }
    }
    
    func getContractOpenOrders(apiKey: String, secretKey: String, passphrase: String) async throws -> [ContractOrder] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/trade/orders-pending"
        
        guard let url = URL(string: "\(baseURL)\(requestPath)?instType=FUTURES&instType=SWAP") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "GET", requestPath: requestPath + "?instType=FUTURES&instType=SWAP")
        let response: OKXOrderResponse = try await performRequest(url: url, headers: headers, responseType: OKXOrderResponse.self)
        
        return response.data.map { order in
            ContractOrder(
                avgPrice: order.avgPx,
                clientOrderId: order.clOrdId ?? "",
                cumQuote: order.fillNotionalUsd,
                executedQty: order.fillSz,
                orderId: Int64(order.ordId) ?? 0,
                origQty: order.sz,
                origType: order.ordType,
                price: order.px,
                reduceOnly: order.reduceOnly == "true",
                side: order.side.uppercased(),
                positionSide: order.posSide.uppercased(),
                status: order.state,
                stopPrice: order.slTriggerPx,
                closePosition: false,
                symbol: order.instId,
                time: Int64(order.cTime) ?? 0,
                timeInForce: order.tgtCcy,
                type: order.ordType,
                activatePrice: nil,
                priceRate: nil,
                updateTime: Int64(order.uTime) ?? 0,
                workingType: "CONTRACT_PRICE",
                priceProtect: false
            )
        }
    }
    
    // MARK: - Order Management Methods
    
    func createSpotOrder(apiKey: String, secretKey: String, passphrase: String, symbol: String, side: String, type: String, quantity: String, price: String?) async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/trade/order"
        
        var orderData: [String: Any] = [
            "instId": symbol,
            "tdMode": "cash",
            "side": side.lowercased(),
            "ordType": type.lowercased(),
            "sz": quantity
        ]
        
        if let price = price, type.lowercased() == "limit" {
            orderData["px"] = price
        }
        
        let body = try JSONSerialization.data(withJSONObject: orderData)
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        
        guard let url = URL(string: "\(baseURL)\(requestPath)") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "POST", requestPath: requestPath, body: bodyString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let errorString = String(data: data, encoding: .utf8) ?? "Invalid response"
            throw OKXAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw OKXAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        struct CreateOrderResponse: Codable {
            let code: String
            let msg: String
            let data: [CreateOrderData]
        }
        
        struct CreateOrderData: Codable {
            let ordId: String
            let clOrdId: String
            let sCode: String
            let sMsg: String
        }
        
        do {
            let orderResponse = try JSONDecoder().decode(CreateOrderResponse.self, from: data)
            if let orderData = orderResponse.data.first {
                return orderData.ordId
            } else {
                throw OKXAPIError.invalidResponse("No order data returned")
            }
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw OKXAPIError.decodingError(error, dataString)
        }
    }
    
    func cancelSpotOrder(apiKey: String, secretKey: String, passphrase: String, symbol: String, orderId: String) async throws -> String {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let requestPath = "/api/v5/trade/cancel-order"
        
        let orderData: [String: Any] = [
            "instId": symbol,
            "ordId": orderId
        ]
        
        let body = try JSONSerialization.data(withJSONObject: orderData)
        let bodyString = String(data: body, encoding: .utf8) ?? ""
        
        guard let url = URL(string: "\(baseURL)\(requestPath)") else {
            throw OKXAPIError.invalidURL
        }
        
        let headers = createHeaders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, timestamp: timestamp, method: "POST", requestPath: requestPath, body: bodyString)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let errorString = String(data: data, encoding: .utf8) ?? "Invalid response"
            throw OKXAPIError.invalidResponse(errorString)
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "HTTP Error: \(httpResponse.statusCode)"
            throw OKXAPIError.httpError(httpResponse.statusCode, errorString)
        }
        
        struct CancelOrderResponse: Codable {
            let code: String
            let msg: String
            let data: [CancelOrderData]
        }
        
        struct CancelOrderData: Codable {
            let ordId: String
            let clOrdId: String
            let sCode: String
            let sMsg: String
        }
        
        do {
            let cancelResponse = try JSONDecoder().decode(CancelOrderResponse.self, from: data)
            if let orderData = cancelResponse.data.first {
                return "Order \(orderData.ordId) cancellation: \(orderData.sMsg)"
            } else {
                throw OKXAPIError.invalidResponse("No cancellation data returned")
            }
        } catch {
            let dataString = String(data: data, encoding: .utf8) ?? "Invalid data"
            throw OKXAPIError.decodingError(error, dataString)
        }
    }
}

enum OKXAPIError: Error, LocalizedError {
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

// MARK: - OKX API Response Models

struct OKXBalanceResponse: Codable {
    let code: String
    let msg: String
    let data: [OKXAccountBalance]
}

struct OKXAccountBalance: Codable {
    let details: [OKXBalanceDetail]
}

struct OKXBalanceDetail: Codable {
    let ccy: String
    let bal: String
    let frozenBal: String
    let availBal: String
    let upl: String
}

struct OKXOrderResponse: Codable {
    let code: String
    let msg: String
    let data: [OKXOrder]
}

struct OKXOrder: Codable {
    let instId: String
    let ordId: String
    let clOrdId: String?
    let px: String
    let sz: String
    let fillSz: String
    let fillNotionalUsd: String
    let avgPx: String
    let state: String
    let side: String
    let posSide: String
    let ordType: String
    let tgtCcy: String
    let notionalUsd: String
    let reduceOnly: String
    let slTriggerPx: String
    let cTime: String
    let uTime: String
}

struct OKXPositionResponse: Codable {
    let code: String
    let msg: String
    let data: [OKXPosition]
}

struct OKXPosition: Codable {
    let instId: String
    let pos: String
    let posSide: String
    let avgPx: String
    let upl: String
    let imr: String
    let mmr: String
    let lever: String
    let mgnMode: String
    let notionalUsd: String
    let margin: String
    let uTime: String
}