import SwiftUI

struct ContentView: View {
    @StateObject private var credentials = BinanceCredentials()
    @StateObject private var dataStore = BinanceDataStore()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with credentials input
                VStack(spacing: 16) {
                    HStack {
                        Text("Qaroto - Binance API Tool")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button("Clear Credentials") {
                            credentials.clearCredentials()
                            clearAllData()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    
                    // API Credentials Input
                    VStack(spacing: 12) {
                        HStack {
                            Text("API Key:")
                                .frame(width: 100, alignment: .leading)
                            SecureField("Enter API Key", text: $credentials.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Secret Key:")
                                .frame(width: 100, alignment: .leading)
                            SecureField("Enter Secret Key", text: $credentials.secretKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Refresh All Data") {
                            Task {
                                await refreshAllData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(credentials.apiKey.isEmpty || credentials.secretKey.isEmpty || dataStore.isLoading)
                        
                        Button("Refresh Current Tab") {
                            Task {
                                await refreshCurrentTab()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(credentials.apiKey.isEmpty || credentials.secretKey.isEmpty || dataStore.isLoading)
                        
                        if dataStore.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = dataStore.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if let lastRefresh = dataStore.lastRefreshTime {
                        Text("Last updated: \(lastRefresh, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.1))
                
                // Tab View for different data sections
                TabView(selection: $selectedTab) {
                    SpotBalanceView(balances: dataStore.spotBalances)
                        .tabItem {
                            Label("Spot Balance", systemImage: "dollarsign.circle")
                        }
                        .tag(0)
                    
                    SpotOrdersView(orders: dataStore.spotOrders)
                        .tabItem {
                            Label("Spot Orders", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    ContractBalanceView(balances: dataStore.contractBalances)
                        .tabItem {
                            Label("Contract Balance", systemImage: "chart.bar")
                        }
                        .tag(2)
                    
                    ContractPositionsView(positions: dataStore.contractPositions)
                        .tabItem {
                            Label("Contract Positions", systemImage: "square.grid.2x2")
                        }
                        .tag(3)
                    
                    ContractOrdersView(orders: dataStore.contractOrders)
                        .tabItem {
                            Label("Contract Orders", systemImage: "list.dash")
                        }
                        .tag(4)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func refreshAllData() async {
        guard !credentials.apiKey.isEmpty && !credentials.secretKey.isEmpty else {
            return
        }
        
        dataStore.isLoading = true
        dataStore.errorMessage = nil
        
        do {
            async let spotBalances = BinanceAPI.shared.getSpotBalance(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
            async let spotOrders = BinanceAPI.shared.getSpotOpenOrders(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
            async let contractBalances = BinanceAPI.shared.getContractBalance(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
            async let contractPositions = BinanceAPI.shared.getContractPositions(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
            async let contractOrders = BinanceAPI.shared.getContractOpenOrders(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
            
            let results = try await (spotBalances, spotOrders, contractBalances, contractPositions, contractOrders)
            
            await MainActor.run {
                dataStore.spotBalances = results.0
                dataStore.spotOrders = results.1
                dataStore.contractBalances = results.2
                dataStore.contractPositions = results.3
                dataStore.contractOrders = results.4
                dataStore.lastRefreshTime = Date()
                dataStore.isLoading = false
            }
        } catch {
            await MainActor.run {
                dataStore.errorMessage = error.localizedDescription
                dataStore.isLoading = false
            }
        }
    }
    
    private func clearAllData() {
        dataStore.spotBalances = []
        dataStore.spotOrders = []
        dataStore.contractBalances = []
        dataStore.contractPositions = []
        dataStore.contractOrders = []
        dataStore.errorMessage = nil
    }
    
    private func refreshCurrentTab() async {
        guard !credentials.apiKey.isEmpty && !credentials.secretKey.isEmpty else {
            return
        }
        
        dataStore.isLoading = true
        dataStore.errorMessage = nil
        
        do {
            switch selectedTab {
            case 0: // Spot Balance
                let balances = try await BinanceAPI.shared.getSpotBalance(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
                await MainActor.run {
                    dataStore.spotBalances = balances
                }
            case 1: // Spot Orders
                let orders = try await BinanceAPI.shared.getSpotOpenOrders(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
                await MainActor.run {
                    dataStore.spotOrders = orders
                }
            case 2: // Contract Balance
                let balances = try await BinanceAPI.shared.getContractBalance(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
                await MainActor.run {
                    dataStore.contractBalances = balances
                }
            case 3: // Contract Positions
                let positions = try await BinanceAPI.shared.getContractPositions(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
                await MainActor.run {
                    dataStore.contractPositions = positions
                }
            case 4: // Contract Orders
                let orders = try await BinanceAPI.shared.getContractOpenOrders(apiKey: credentials.apiKey, secretKey: credentials.secretKey)
                await MainActor.run {
                    dataStore.contractOrders = orders
                }
            default:
                break
            }
            
            await MainActor.run {
                dataStore.lastRefreshTime = Date()
                dataStore.isLoading = false
            }
        } catch {
            await MainActor.run {
                dataStore.errorMessage = error.localizedDescription
                dataStore.isLoading = false
            }
        }
    }
}

// MARK: - Detail Views

struct SpotBalanceView: View {
    let balances: [SpotBalance]
    
    var body: some View {
        List(balances, id: \.asset) { balance in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(balance.asset)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    if let total = Double(balance.free).map({ $0 + (Double(balance.locked) ?? 0) }) {
                        Text("Total: \(total, specifier: "%.8f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(balance.free)
                            .font(.subheadline)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Locked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(balance.locked)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Spot Balances (\(balances.count))")
    }
}

struct SpotOrdersView: View {
    let orders: [SpotOrder]
    
    var body: some View {
        List(orders, id: \.orderId) { order in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(order.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(order.side)
                        .foregroundColor(order.side == "BUY" ? .green : .red)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(order.side == "BUY" ? .green.opacity(0.1) : .red.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(order.price)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center) {
                        Text("Quantity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(order.origQty)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Filled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(order.executedQty)
                            .font(.subheadline)
                    }
                }
                
                HStack {
                    Text("\(order.type) • \(order.status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Order ID: \(order.orderId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Spot Orders (\(orders.count))")
    }
}

struct ContractBalanceView: View {
    let balances: [ContractBalance]
    
    var body: some View {
        List(balances, id: \.asset) { balance in
            VStack(alignment: .leading, spacing: 4) {
                Text(balance.asset)
                    .font(.headline)
                HStack {
                    Text("Balance: \(balance.balance)")
                    Spacer()
                    Text("Available: \(balance.availableBalance)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Contract Balances")
    }
}

struct ContractPositionsView: View {
    let positions: [ContractPosition]
    
    var body: some View {
        List(positions, id: \.symbol) { position in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(position.symbol)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(position.positionSide)
                        .foregroundColor(position.positionSide == "LONG" ? .green : .red)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(position.positionSide == "LONG" ? .green.opacity(0.1) : .red.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(position.positionAmt)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center) {
                        Text("Entry Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(position.entryPrice)
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Leverage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(position.leverage)x")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Text("Unrealized PnL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(position.unrealizedProfit)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Double(position.unrealizedProfit) ?? 0 >= 0 ? .green : .red)
                }
                
                if let updateTime = position.updateTime {
                    Text("Updated: \(Date(timeIntervalSince1970: Double(updateTime) / 1000), style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("Contract Positions (\(positions.count))")
    }
}

struct ContractOrdersView: View {
    let orders: [ContractOrder]
    
    var body: some View {
        List(orders, id: \.orderId) { order in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(order.symbol)
                        .font(.headline)
                    Spacer()
                    Text(order.side)
                        .foregroundColor(order.side == "BUY" ? .green : .red)
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Price: \(order.price)")
                    Spacer()
                    Text("Qty: \(order.origQty)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                HStack {
                    Text("Type: \(order.type)")
                    Spacer()
                    Text("Status: \(order.status)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 2)
        }
        .navigationTitle("Contract Orders")
    }
}

#Preview {
    ContentView()
}