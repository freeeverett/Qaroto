import Foundation

class ExchangeAPIManager {
    static let shared = ExchangeAPIManager()
    
    private init() {}
    
    func getSpotBalance(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "") async throws -> [SpotBalance] {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.getSpotBalance(apiKey: apiKey, secretKey: secretKey)
        case .okx:
            return try await OKXAPI.shared.getSpotBalance(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
        }
    }
    
    func getSpotOpenOrders(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "") async throws -> [SpotOrder] {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.getSpotOpenOrders(apiKey: apiKey, secretKey: secretKey)
        case .okx:
            return try await OKXAPI.shared.getSpotOpenOrders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
        }
    }
    
    func getContractBalance(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "") async throws -> [ContractBalance] {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.getContractBalance(apiKey: apiKey, secretKey: secretKey)
        case .okx:
            return try await OKXAPI.shared.getContractBalance(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
        }
    }
    
    func getContractPositions(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "") async throws -> [ContractPosition] {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.getContractPositions(apiKey: apiKey, secretKey: secretKey)
        case .okx:
            return try await OKXAPI.shared.getContractPositions(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
        }
    }
    
    func getContractOpenOrders(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "") async throws -> [ContractOrder] {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.getContractOpenOrders(apiKey: apiKey, secretKey: secretKey)
        case .okx:
            return try await OKXAPI.shared.getContractOpenOrders(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase)
        }
    }
    
    // MARK: - Order Management Methods
    
    func createSpotOrder(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "", symbol: String, side: String, type: String, quantity: String, price: String?) async throws -> String {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.createSpotOrder(apiKey: apiKey, secretKey: secretKey, symbol: symbol, side: side, type: type, quantity: quantity, price: price)
        case .okx:
            return try await OKXAPI.shared.createSpotOrder(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, symbol: symbol, side: side, type: type, quantity: quantity, price: price)
        }
    }
    
    func cancelSpotOrder(exchange: Exchange, apiKey: String, secretKey: String, passphrase: String = "", symbol: String, orderId: String) async throws -> String {
        switch exchange {
        case .binance:
            return try await BinanceAPI.shared.cancelSpotOrder(apiKey: apiKey, secretKey: secretKey, symbol: symbol, orderId: orderId)
        case .okx:
            return try await OKXAPI.shared.cancelSpotOrder(apiKey: apiKey, secretKey: secretKey, passphrase: passphrase, symbol: symbol, orderId: orderId)
        }
    }
}