import SwiftUI

struct ContentView: View {
    @StateObject private var credentials = BinanceCredentials()
    @StateObject private var dataStore = BinanceDataStore()
    @State private var selectedTab = 0
    
    // Order form state
    @State private var createOrderSymbol = ""
    @State private var createOrderSide = "BUY"
    @State private var createOrderType = "LIMIT"
    @State private var createOrderPrice = ""
    @State private var createOrderQuantity = ""
    @State private var createOrderLoading = false
    @State private var createOrderMessage = ""
    
    @State private var cancelOrderSymbol = ""
    @State private var cancelOrderId = ""
    @State private var cancelOrderLoading = false
    @State private var cancelOrderMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Enhanced Header
                    headerView
                    
                    // Main Content
                    if !credentials.apiKey.isEmpty && !credentials.secretKey.isEmpty && (!credentials.requiresPassphrase || !credentials.passphrase.isEmpty) {
                        tabView
                    } else {
                        emptyStateView
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 20) {
            // Title and Clear Button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qaroto")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Multi-Exchange API Tool")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Clear") {
                    credentials.clearCredentials()
                    clearAllData()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .tint(.red)
            }
            
            // Exchange Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Exchange")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Picker("Exchange", selection: $credentials.exchange) {
                    ForEach(Exchange.allCases, id: \.self) { exchange in
                        HStack {
                            Image(systemName: exchange == .binance ? "b.circle.fill" : "o.circle.fill")
                                .foregroundColor(exchange == .binance ? .orange : .blue)
                            Text(exchange.displayName)
                        }
                        .tag(exchange)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // API Credentials Input
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Credentials")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("API Key:")
                                .frame(width: 100, alignment: .leading)
                                .foregroundColor(.secondary)
                            SecureField("Enter API Key", text: $credentials.apiKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        HStack {
                            Text("Secret Key:")
                                .frame(width: 100, alignment: .leading)
                                .foregroundColor(.secondary)
                            SecureField("Enter Secret Key", text: $credentials.secretKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if credentials.requiresPassphrase {
                            HStack {
                                Text("Passphrase:")
                                    .frame(width: 100, alignment: .leading)
                                    .foregroundColor(.secondary)
                                SecureField("Enter Passphrase", text: $credentials.passphrase)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button("Refresh All Data") {
                    Task {
                        await refreshAllData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRefresh || dataStore.isLoading)
                
                if dataStore.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Status Messages
            VStack(spacing: 8) {
                if let errorMessage = dataStore.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let lastRefresh = dataStore.lastRefreshTime {
                    Text("Last updated: \(lastRefresh, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .padding()
    }
    
    // MARK: - Tab View
    
    private var tabView: some View {
        VStack(spacing: 0) {
            // Tab Selection
            Picker("Tab", selection: $selectedTab) {
                Text("Current Information").tag(0)
                Text("Order Operations").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            // Tab Content
            Group {
                if selectedTab == 0 {
                    currentInformationView
                } else {
                    orderOperationsView
                }
            }
        }
    }
    
    // MARK: - Current Information View (formerly mainContentView)
    
    private var currentInformationView: some View {
        LazyVStack(spacing: 20) {
            // Spot Balance Section
            sectionCard(title: "Spot Balance", icon: "dollarsign.circle.fill", color: .green) {
                if dataStore.spotBalances.isEmpty && !dataStore.isLoading {
                    emptyDataView(message: "No spot balances found")
                } else {
                    spotBalanceList
                }
            }
            
            // Spot Orders Section
            sectionCard(title: "Spot Orders", icon: "list.bullet.circle.fill", color: .blue) {
                if dataStore.spotOrders.isEmpty && !dataStore.isLoading {
                    emptyDataView(message: "No spot orders found")
                } else {
                    spotOrdersList
                }
            }
            
            // Contract Balance Section
            sectionCard(title: "Contract Balance", icon: "chart.bar.fill", color: .orange) {
                if dataStore.contractBalances.isEmpty && !dataStore.isLoading {
                    emptyDataView(message: "No contract balances found")
                } else {
                    contractBalanceList
                }
            }
            
            // Contract Positions Section
            sectionCard(title: "Contract Positions", icon: "square.grid.2x2.fill", color: .purple) {
                if dataStore.contractPositions.isEmpty && !dataStore.isLoading {
                    emptyDataView(message: "No contract positions found")
                } else {
                    contractPositionsList
                }
            }
            
            // Contract Orders Section
            sectionCard(title: "Contract Orders", icon: "list.dash.fill", color: .indigo) {
                if dataStore.contractOrders.isEmpty && !dataStore.isLoading {
                    emptyDataView(message: "No contract orders found")
                } else {
                    contractOrdersList
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Order Operations View
    
    private var orderOperationsView: some View {
        VStack(spacing: 20) {
            // Create Order Section
            sectionCard(title: "Create Order", icon: "plus.circle.fill", color: .green) {
                createOrderView
            }
            
            // Cancel Order Section
            sectionCard(title: "Cancel Order", icon: "minus.circle.fill", color: .red) {
                cancelOrderView
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Create Order View
    
    private var createOrderView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // Order creation form
                VStack(spacing: 12) {
                    HStack {
                        Text("Symbol:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("e.g., BTCUSDT", text: $createOrderSymbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    
                    HStack {
                        Text("Side:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        Picker("Side", selection: $createOrderSide) {
                            Text("BUY").tag("BUY")
                            Text("SELL").tag("SELL")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    HStack {
                        Text("Type:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        Picker("Type", selection: $createOrderType) {
                            Text("LIMIT").tag("LIMIT")
                            Text("MARKET").tag("MARKET")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    if createOrderType == "LIMIT" {
                        HStack {
                            Text("Price:")
                                .frame(width: 80, alignment: .leading)
                                .foregroundColor(.secondary)
                            TextField("Price", text: $createOrderPrice)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    HStack {
                        Text("Quantity:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("Quantity", text: $createOrderQuantity)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                
                HStack {
                    Button("Create Order") {
                        Task {
                            await createOrder()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreateOrder || createOrderLoading)
                    .frame(maxWidth: .infinity)
                    
                    if createOrderLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if !createOrderMessage.isEmpty {
                    Text(createOrderMessage)
                        .font(.caption)
                        .foregroundColor(createOrderMessage.contains("successfully") ? .green : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((createOrderMessage.contains("successfully") ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Cancel Order View
    
    private var cancelOrderView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                // Order cancellation form
                VStack(spacing: 12) {
                    HStack {
                        Text("Symbol:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("e.g., BTCUSDT", text: $cancelOrderSymbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                    
                    HStack {
                        Text("Order ID:")
                            .frame(width: 80, alignment: .leading)
                            .foregroundColor(.secondary)
                        TextField("Order ID", text: $cancelOrderId)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                HStack {
                    Button("Cancel Order") {
                        Task {
                            await cancelOrder()
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .tint(.red)
                    .disabled(!canCancelOrder || cancelOrderLoading)
                    .frame(maxWidth: .infinity)
                    
                    if cancelOrderLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if !cancelOrderMessage.isEmpty {
                    Text(cancelOrderMessage)
                        .font(.caption)
                        .foregroundColor(cancelOrderMessage.contains("cancelled") ? .green : .red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((cancelOrderMessage.contains("cancelled") ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Enter Your API Credentials")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Please enter your API credentials above to start viewing your exchange data.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 80)
    }
    
    // MARK: - Helper Views
    
    private func sectionCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func emptyDataView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray.fill")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Data Lists
    
    private var spotBalanceList: some View {
        LazyVStack(spacing: 12) {
            ForEach(dataStore.spotBalances, id: \.asset) { balance in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(balance.asset)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(balance.free)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Locked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(balance.locked)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if let total = Double(balance.free).map({ $0 + (Double(balance.locked) ?? 0) }) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(total, specifier: "%.8f")")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var spotOrdersList: some View {
        LazyVStack(spacing: 12) {
            ForEach(dataStore.spotOrders, id: \.orderId) { order in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(order.symbol)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(order.side)
                            .foregroundColor(order.side == "BUY" ? .green : .red)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(order.side == "BUY" ? .green.opacity(0.15) : .red.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.price)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Quantity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.origQty)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Filled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.executedQty)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Text("\(order.type) • \(order.status)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("ID: \(order.orderId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var contractBalanceList: some View {
        LazyVStack(spacing: 12) {
            ForEach(dataStore.contractBalances, id: \.asset) { balance in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(balance.asset)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(balance.balance)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(balance.availableBalance)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var contractPositionsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(dataStore.contractPositions, id: \.symbol) { position in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(position.symbol)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(position.positionSide)
                            .foregroundColor(position.positionSide == "LONG" ? .green : .red)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(position.positionSide == "LONG" ? .green.opacity(0.15) : .red.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(position.positionAmt)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Entry Price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(position.entryPrice)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Leverage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(position.leverage)x")
                                .font(.subheadline)
                                .fontWeight(.bold)
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
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private var contractOrdersList: some View {
        LazyVStack(spacing: 12) {
            ForEach(dataStore.contractOrders, id: \.orderId) { order in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(order.symbol)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(order.side)
                            .foregroundColor(order.side == "BUY" ? .green : .red)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(order.side == "BUY" ? .green.opacity(0.15) : .red.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Price")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.price)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Quantity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.origQty)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(order.status)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Text("Type: \(order.type)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canRefresh: Bool {
        !credentials.apiKey.isEmpty && 
        !credentials.secretKey.isEmpty && 
        (!credentials.requiresPassphrase || !credentials.passphrase.isEmpty)
    }
    
    private var canCreateOrder: Bool {
        canRefresh && 
        !createOrderSymbol.isEmpty && 
        !createOrderQuantity.isEmpty &&
        (createOrderType == "MARKET" || !createOrderPrice.isEmpty)
    }
    
    private var canCancelOrder: Bool {
        canRefresh && 
        !cancelOrderSymbol.isEmpty && 
        !cancelOrderId.isEmpty
    }
    
    // MARK: - Private Methods
    
    private func refreshAllData() async {
        guard canRefresh else { return }
        
        dataStore.isLoading = true
        dataStore.errorMessage = nil
        
        do {
            async let spotBalances = ExchangeAPIManager.shared.getSpotBalance(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase
            )
            async let spotOrders = ExchangeAPIManager.shared.getSpotOpenOrders(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase
            )
            async let contractBalances = ExchangeAPIManager.shared.getContractBalance(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase
            )
            async let contractPositions = ExchangeAPIManager.shared.getContractPositions(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase
            )
            async let contractOrders = ExchangeAPIManager.shared.getContractOpenOrders(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase
            )
            
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
                // Show detailed error message for better debugging
                if let apiError = error as? BinanceAPIError {
                    dataStore.errorMessage = apiError.errorDescription ?? "Unknown Binance API error"
                } else if let apiError = error as? OKXAPIError {
                    dataStore.errorMessage = apiError.errorDescription ?? "Unknown OKX API error"
                } else {
                    dataStore.errorMessage = "Error: \(error.localizedDescription)"
                }
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
        dataStore.lastRefreshTime = nil
    }
    
    // MARK: - Order Management Methods
    
    private func createOrder() async {
        guard canCreateOrder else { return }
        
        createOrderLoading = true
        createOrderMessage = ""
        
        do {
            let price = createOrderType == "LIMIT" ? createOrderPrice : nil
            let orderId = try await ExchangeAPIManager.shared.createSpotOrder(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase,
                symbol: createOrderSymbol,
                side: createOrderSide,
                type: createOrderType,
                quantity: createOrderQuantity,
                price: price
            )
            
            await MainActor.run {
                createOrderMessage = "Order created successfully! ID: \(orderId)"
                createOrderLoading = false
                
                // Clear form
                createOrderSymbol = ""
                createOrderPrice = ""
                createOrderQuantity = ""
                
                // Refresh data to show new order
                Task {
                    await refreshAllData()
                }
            }
        } catch {
            await MainActor.run {
                createOrderMessage = "Error creating order: \(error.localizedDescription)"
                createOrderLoading = false
            }
        }
    }
    
    private func cancelOrder() async {
        guard canCancelOrder else { return }
        
        cancelOrderLoading = true
        cancelOrderMessage = ""
        
        do {
            let result = try await ExchangeAPIManager.shared.cancelSpotOrder(
                exchange: credentials.exchange,
                apiKey: credentials.apiKey,
                secretKey: credentials.secretKey,
                passphrase: credentials.passphrase,
                symbol: cancelOrderSymbol,
                orderId: cancelOrderId
            )
            
            await MainActor.run {
                cancelOrderMessage = result
                cancelOrderLoading = false
                
                // Clear form
                cancelOrderSymbol = ""
                cancelOrderId = ""
                
                // Refresh data to show updated orders
                Task {
                    await refreshAllData()
                }
            }
        } catch {
            await MainActor.run {
                cancelOrderMessage = "Error cancelling order: \(error.localizedDescription)"
                cancelOrderLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}