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
}