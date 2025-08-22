import Foundation

// MARK: - Binance API Models

struct SpotBalance: Codable {
    let asset: String
    let free: String
    let locked: String
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
    
    // Memberwise initializer
    init(symbol: String, initialMargin: String, maintMargin: String, unrealizedProfit: String, 
         positionInitialMargin: String, openOrderInitialMargin: String, leverage: String, 
         isolated: Bool, entryPrice: String, maxNotional: String, positionSide: String, 
         positionAmt: String, notional: String, isolatedWallet: String, updateTime: Int64?) {
        self.symbol = symbol
        self.initialMargin = initialMargin
        self.maintMargin = maintMargin
        self.unrealizedProfit = unrealizedProfit
        self.positionInitialMargin = positionInitialMargin
        self.openOrderInitialMargin = openOrderInitialMargin
        self.leverage = leverage
        self.isolated = isolated
        self.entryPrice = entryPrice
        self.maxNotional = maxNotional
        self.positionSide = positionSide
        self.positionAmt = positionAmt
        self.notional = notional
        self.isolatedWallet = isolatedWallet
        self.updateTime = updateTime
    }
    
    // Custom decoding to handle both positionAmt and postationAmt (API typo)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        
        symbol = try container.decode(String.self, forKey: AnyCodingKey("symbol"))
        initialMargin = try container.decode(String.self, forKey: AnyCodingKey("initialMargin"))
        maintMargin = try container.decode(String.self, forKey: AnyCodingKey("maintMargin"))
        unrealizedProfit = try container.decode(String.self, forKey: AnyCodingKey("unrealizedProfit"))
        positionInitialMargin = try container.decode(String.self, forKey: AnyCodingKey("positionInitialMargin"))
        openOrderInitialMargin = try container.decode(String.self, forKey: AnyCodingKey("openOrderInitialMargin"))
        leverage = try container.decode(String.self, forKey: AnyCodingKey("leverage"))
        isolated = try container.decode(Bool.self, forKey: AnyCodingKey("isolated"))
        entryPrice = try container.decode(String.self, forKey: AnyCodingKey("entryPrice"))
        maxNotional = try container.decode(String.self, forKey: AnyCodingKey("maxNotional"))
        positionSide = try container.decode(String.self, forKey: AnyCodingKey("positionSide"))
        notional = try container.decode(String.self, forKey: AnyCodingKey("notional"))
        isolatedWallet = try container.decode(String.self, forKey: AnyCodingKey("isolatedWallet"))
        updateTime = try container.decodeIfPresent(Int64.self, forKey: AnyCodingKey("updateTime"))
        
        // Handle both positionAmt and postationAmt (API typo)
        if let correctPositionAmt = try? container.decode(String.self, forKey: AnyCodingKey("positionAmt")) {
            positionAmt = correctPositionAmt
        } else if let typoPositionAmt = try? container.decode(String.self, forKey: AnyCodingKey("postationAmt")) {
            positionAmt = typoPositionAmt
        } else {
            throw DecodingError.keyNotFound(AnyCodingKey("positionAmt"), 
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Expected either 'positionAmt' or 'postationAmt' key"))
        }
    }
}

// Helper struct for dynamic coding keys
private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(_ string: String) {
        self.stringValue = string
        self.intValue = nil
    }
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
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

enum Exchange: String, CaseIterable {
    case binance = "Binance"
    case okx = "OKX"
    
    var displayName: String {
        return self.rawValue
    }
}

class BinanceCredentials: ObservableObject {
    @Published var exchange: Exchange = .binance
    @Published var apiKey: String = ""
    @Published var secretKey: String = ""
    @Published var passphrase: String = "" // For OKX
    
    var requiresPassphrase: Bool {
        return exchange == .okx
    }
    
    func clearCredentials() {
        apiKey = ""
        secretKey = ""
        passphrase = ""
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