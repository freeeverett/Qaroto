package ui

import (
	"context"
	"fmt"
	"strconv"
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/dialog"
	"fyne.io/fyne/v2/widget"
	"github.com/freeeverett/qaroto/internal/exchange"
	"github.com/freeeverett/qaroto/internal/models"
)

// App represents the main application
type App struct {
	window    fyne.Window
	exchange  exchange.Exchange
	
	// UI components
	apiKeyEntry    *widget.Entry
	apiSecretEntry *widget.Entry
	exchangeSelect *widget.Select
	connectBtn     *widget.Button
	
	// Account info components
	accountInfoContainer *container.AppTabs
	spotBalanceList      *widget.List
	futuresBalanceList   *widget.List
	positionList         *widget.List
	
	// Order components
	orderSymbolEntry    *widget.Entry
	orderSideSelect     *widget.Select
	orderTypeSelect     *widget.Select
	orderQuantityEntry  *widget.Entry
	orderPriceEntry     *widget.Entry
	createOrderBtn      *widget.Button
	
	// Data
	spotBalances    []models.SpotBalance
	futuresBalances []models.FuturesBalance
	positions       []models.Position
}

// NewApp creates a new application instance
func NewApp(window fyne.Window) *App {
	app := &App{
		window: window,
	}
	app.setupUI()
	return app
}

// setupUI initializes the user interface
func (a *App) setupUI() {
	// API credentials section
	a.apiKeyEntry = widget.NewEntry()
	a.apiKeyEntry.SetPlaceHolder("Enter API Key")
	
	a.apiSecretEntry = widget.NewPasswordEntry()
	a.apiSecretEntry.SetPlaceHolder("Enter API Secret")
	
	a.exchangeSelect = widget.NewSelect([]string{"binance", "okx"}, nil)
	a.exchangeSelect.SetSelected("binance")
	
	a.connectBtn = widget.NewButton("Connect", a.onConnect)
	
	credentialsForm := container.NewVBox(
		widget.NewLabel("Exchange API Credentials"),
		widget.NewLabel("Exchange:"),
		a.exchangeSelect,
		widget.NewLabel("API Key:"),
		a.apiKeyEntry,
		widget.NewLabel("API Secret:"),
		a.apiSecretEntry,
		a.connectBtn,
	)
	
	// Account info section
	a.setupAccountInfoUI()
	
	// Order section
	a.setupOrderUI()
	
	// Main layout
	mainContainer := container.NewVBox(
		credentialsForm,
		widget.NewSeparator(),
		a.accountInfoContainer,
		widget.NewSeparator(),
		a.createOrderSection(),
	)
	
	scrollContainer := container.NewScroll(mainContainer)
	scrollContainer.SetMinSize(fyne.NewSize(800, 600))
	
	a.window.SetContent(scrollContainer)
}

// setupAccountInfoUI creates the account information display
func (a *App) setupAccountInfoUI() {
	// Spot balances list
	a.spotBalanceList = widget.NewList(
		func() int { return len(a.spotBalances) },
		func() fyne.CanvasObject {
			return container.NewHBox(
				widget.NewLabel("Asset"),
				widget.NewLabel("Free"),
				widget.NewLabel("Locked"),
				widget.NewLabel("Total"),
			)
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			if id < len(a.spotBalances) {
				balance := a.spotBalances[id]
				cont := obj.(*fyne.Container)
				cont.Objects[0].(*widget.Label).SetText(balance.Asset)
				cont.Objects[1].(*widget.Label).SetText(fmt.Sprintf("%.6f", balance.Free))
				cont.Objects[2].(*widget.Label).SetText(fmt.Sprintf("%.6f", balance.Locked))
				cont.Objects[3].(*widget.Label).SetText(fmt.Sprintf("%.6f", balance.Total))
			}
		},
	)
	
	// Futures balances list
	a.futuresBalanceList = widget.NewList(
		func() int { return len(a.futuresBalances) },
		func() fyne.CanvasObject {
			return container.NewHBox(
				widget.NewLabel("Asset"),
				widget.NewLabel("Wallet"),
				widget.NewLabel("Unrealized PNL"),
				widget.NewLabel("Margin"),
				widget.NewLabel("Available"),
			)
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			if id < len(a.futuresBalances) {
				balance := a.futuresBalances[id]
				cont := obj.(*fyne.Container)
				cont.Objects[0].(*widget.Label).SetText(balance.Asset)
				cont.Objects[1].(*widget.Label).SetText(fmt.Sprintf("%.2f", balance.WalletBalance))
				cont.Objects[2].(*widget.Label).SetText(fmt.Sprintf("%.2f", balance.UnrealizedPNL))
				cont.Objects[3].(*widget.Label).SetText(fmt.Sprintf("%.2f", balance.MarginBalance))
				cont.Objects[4].(*widget.Label).SetText(fmt.Sprintf("%.2f", balance.AvailableBalance))
			}
		},
	)
	
	// Positions list
	a.positionList = widget.NewList(
		func() int { return len(a.positions) },
		func() fyne.CanvasObject {
			return container.NewHBox(
				widget.NewLabel("Symbol"),
				widget.NewLabel("Size"),
				widget.NewLabel("Entry Price"),
				widget.NewLabel("Mark Price"),
				widget.NewLabel("PNL"),
				widget.NewLabel("Side"),
			)
		},
		func(id widget.ListItemID, obj fyne.CanvasObject) {
			if id < len(a.positions) {
				position := a.positions[id]
				cont := obj.(*fyne.Container)
				cont.Objects[0].(*widget.Label).SetText(position.Symbol)
				cont.Objects[1].(*widget.Label).SetText(fmt.Sprintf("%.6f", position.PositionAmt))
				cont.Objects[2].(*widget.Label).SetText(fmt.Sprintf("%.2f", position.EntryPrice))
				cont.Objects[3].(*widget.Label).SetText(fmt.Sprintf("%.2f", position.MarkPrice))
				cont.Objects[4].(*widget.Label).SetText(fmt.Sprintf("%.2f", position.UnrealizedPNL))
				cont.Objects[5].(*widget.Label).SetText(position.PositionSide)
			}
		},
	)
	
	refreshBtn := widget.NewButton("Refresh Account Info", a.onRefreshAccountInfo)
	
	a.accountInfoContainer = container.NewAppTabs(
		container.NewTabItem("Spot Balances", container.NewVBox(refreshBtn, a.spotBalanceList)),
		container.NewTabItem("Futures Balances", a.futuresBalanceList),
		container.NewTabItem("Positions", a.positionList),
	)
}

// setupOrderUI creates the order creation interface
func (a *App) setupOrderUI() {
	a.orderSymbolEntry = widget.NewEntry()
	a.orderSymbolEntry.SetPlaceHolder("e.g., BTCUSDT")
	
	a.orderSideSelect = widget.NewSelect([]string{"BUY", "SELL"}, nil)
	a.orderSideSelect.SetSelected("BUY")
	
	a.orderTypeSelect = widget.NewSelect([]string{"MARKET", "LIMIT"}, nil)
	a.orderTypeSelect.SetSelected("LIMIT")
	
	a.orderQuantityEntry = widget.NewEntry()
	a.orderQuantityEntry.SetPlaceHolder("Quantity")
	
	a.orderPriceEntry = widget.NewEntry()
	a.orderPriceEntry.SetPlaceHolder("Price (for limit orders)")
	
	a.createOrderBtn = widget.NewButton("Create Order", a.onCreateOrder)
}

// createOrderSection creates the order management section
func (a *App) createOrderSection() fyne.CanvasObject {
	return container.NewVBox(
		widget.NewLabel("Create Order"),
		container.NewGridWithColumns(2,
			widget.NewLabel("Symbol:"),
			a.orderSymbolEntry,
			widget.NewLabel("Side:"),
			a.orderSideSelect,
			widget.NewLabel("Type:"),
			a.orderTypeSelect,
			widget.NewLabel("Quantity:"),
			a.orderQuantityEntry,
			widget.NewLabel("Price:"),
			a.orderPriceEntry,
		),
		a.createOrderBtn,
	)
}

// onConnect handles the connect button click
func (a *App) onConnect() {
	apiKey := a.apiKeyEntry.Text
	apiSecret := a.apiSecretEntry.Text
	exchangeType := a.exchangeSelect.Selected
	
	if apiKey == "" || apiSecret == "" {
		dialog.ShowError(fmt.Errorf("Please enter both API key and secret"), a.window)
		return
	}
	
	// Create exchange instance (using mock for demo)
	var exchangeTypeModel models.ExchangeType
	switch exchangeType {
	case "binance":
		exchangeTypeModel = models.ExchangeBinance
	case "okx":
		exchangeTypeModel = models.ExchangeOKX
	default:
		exchangeTypeModel = models.ExchangeBinance
	}
	
	a.exchange = exchange.NewMockExchange(exchangeTypeModel)
	a.exchange.SetCredentials(apiKey, apiSecret)
	
	dialog.ShowInformation("Connected", fmt.Sprintf("Successfully connected to %s", exchangeType), a.window)
	
	// Automatically refresh account info
	a.onRefreshAccountInfo()
}

// onRefreshAccountInfo handles the refresh account info button click
func (a *App) onRefreshAccountInfo() {
	if a.exchange == nil {
		dialog.ShowError(fmt.Errorf("Please connect to an exchange first"), a.window)
		return
	}
	
	// Show loading dialog
	progressDialog := dialog.NewProgressInfinite("Loading", "Fetching account information...", a.window)
	progressDialog.Show()
	
	go func() {
		defer progressDialog.Hide()
		
		ctx := context.Background()
		accountInfo, err := a.exchange.GetAccountInfo(ctx)
		if err != nil {
			dialog.ShowError(fmt.Errorf("Failed to get account info: %v", err), a.window)
			return
		}
		
		// Update data and refresh UI
		a.spotBalances = accountInfo.SpotBalances
		a.futuresBalances = accountInfo.FuturesBalances
		a.positions = accountInfo.Positions
		
		a.spotBalanceList.Refresh()
		a.futuresBalanceList.Refresh()
		a.positionList.Refresh()
	}()
}

// onCreateOrder handles the create order button click
func (a *App) onCreateOrder() {
	if a.exchange == nil {
		dialog.ShowError(fmt.Errorf("Please connect to an exchange first"), a.window)
		return
	}
	
	symbol := a.orderSymbolEntry.Text
	side := a.orderSideSelect.Selected
	orderType := a.orderTypeSelect.Selected
	quantityStr := a.orderQuantityEntry.Text
	priceStr := a.orderPriceEntry.Text
	
	if symbol == "" || side == "" || orderType == "" || quantityStr == "" {
		dialog.ShowError(fmt.Errorf("Please fill in all required fields"), a.window)
		return
	}
	
	quantity, err := strconv.ParseFloat(quantityStr, 64)
	if err != nil {
		dialog.ShowError(fmt.Errorf("Invalid quantity: %v", err), a.window)
		return
	}
	
	var price float64
	if orderType == "LIMIT" {
		if priceStr == "" {
			dialog.ShowError(fmt.Errorf("Price is required for limit orders"), a.window)
			return
		}
		price, err = strconv.ParseFloat(priceStr, 64)
		if err != nil {
			dialog.ShowError(fmt.Errorf("Invalid price: %v", err), a.window)
			return
		}
	}
	
	req := &models.NewOrderRequest{
		Symbol:   symbol,
		Side:     models.OrderSide(side),
		Type:     models.OrderType(orderType),
		Quantity: quantity,
		Price:    price,
	}
	
	// Show loading dialog
	progressDialog := dialog.NewProgressInfinite("Creating Order", "Submitting order...", a.window)
	progressDialog.Show()
	
	go func() {
		defer progressDialog.Hide()
		
		ctx := context.Background()
		order, err := a.exchange.CreateOrder(ctx, req)
		if err != nil {
			dialog.ShowError(fmt.Errorf("Failed to create order: %v", err), a.window)
			return
		}
		
		dialog.ShowInformation("Order Created", 
			fmt.Sprintf("Order created successfully!\nOrder ID: %s\nStatus: %s", 
				order.OrderID, order.Status), a.window)
		
		// Clear form
		a.orderSymbolEntry.SetText("")
		a.orderQuantityEntry.SetText("")
		a.orderPriceEntry.SetText("")
	}()
}