import Foundation

// MARK: - Binance API Models

struct SpotBalance: Codable {
    let asset: String
    let free: String
    let locked: String
}

struct SpotBalanceResponse: Codable {
    let balances: [SpotBalance]
}

struct SpotOrder: Codable {
    let symbol: String
    let orderId: Int64
    let orderListId: Int64
    let clientOrderId: String
    let price: String
    let origQty: String
    let executedQty: String
    let cummulativeQuoteQty: String
    let status: String
    let timeInForce: String
    let type: String
    let side: String
    let stopPrice: String
    let icebergQty: String
    let time: Int64
    let updateTime: Int64
    let isWorking: Bool
    let origQuoteOrderQty: String
}

struct ContractBalance: Codable {
    let accountAlias: String?
    let asset: String
    let balance: String
    let crossWalletBalance: String
    let crossUnPnl: String
    let availableBalance: String
    let maxWithdrawAmount: String
    let marginAvailable: Bool?
    let updateTime: Int64?
}

struct ContractBalanceResponse: Codable {
    let totalInitialMargin: String?
    let totalMaintMargin: String?
    let totalWalletBalance: String?
    let totalUnrealizedProfit: String?
    let totalMarginBalance: String?
    let totalPositionInitialMargin: String?
    let totalOpenOrderInitialMargin: String?
    let totalCrossWalletBalance: String?
    let totalCrossUnPnl: String?
    let availableBalance: String?
    let maxWithdrawAmount: String?
    let assets: [ContractBalance]?
    let positions: [ContractPosition]?
}

struct ContractPosition: Codable {
    let symbol: String
    let initialMargin: String
    let maintMargin: String
    let unrealizedProfit: String
    let positionInitialMargin: String
    let openOrderInitialMargin: String
    let leverage: String
    let isolated: Bool
    let entryPrice: String
    let maxNotional: String
    let positionSide: String
    let positionAmt: String
    let notional: String
    let isolatedWallet: String
    let updateTime: Int64?
}

struct ContractOrder: Codable {
    let avgPrice: String
    let clientOrderId: String
    let cumQuote: String
    let executedQty: String
    let orderId: Int64
    let origQty: String
    let origType: String
    let price: String
    let reduceOnly: Bool
    let side: String
    let positionSide: String
    let status: String
    let stopPrice: String
    let closePosition: Bool
    let symbol: String
    let time: Int64
    let timeInForce: String
    let type: String
    let activatePrice: String?
    let priceRate: String?
    let updateTime: Int64
    let workingType: String
    let priceProtect: Bool
}

// MARK: - App State Models

class BinanceCredentials: ObservableObject {
    @Published var apiKey: String = ""
    @Published var secretKey: String = ""
    
    func clearCredentials() {
        apiKey = ""
        secretKey = ""
    }
}

class BinanceDataStore: ObservableObject {
    @Published var spotBalances: [SpotBalance] = []
    @Published var spotOrders: [SpotOrder] = []
    @Published var contractBalances: [ContractBalance] = []
    @Published var contractPositions: [ContractPosition] = []
    @Published var contractOrders: [ContractOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshTime: Date?
}