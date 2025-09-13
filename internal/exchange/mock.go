package exchange

import (
	"context"
	"fmt"
	"math/rand"
	"time"
	"github.com/freeeverett/qaroto/internal/models"
)

// MockExchange provides a mock implementation for testing
type MockExchange struct {
	exchangeType models.ExchangeType
	apiKey       string
	apiSecret    string
}

// NewMockExchange creates a new mock exchange instance
func NewMockExchange(exchangeType models.ExchangeType) *MockExchange {
	return &MockExchange{
		exchangeType: exchangeType,
	}
}

// SetCredentials sets the API credentials
func (m *MockExchange) SetCredentials(apiKey, apiSecret string) {
	m.apiKey = apiKey
	m.apiSecret = apiSecret
}

// GetAccountInfo returns mock account information
func (m *MockExchange) GetAccountInfo(ctx context.Context) (*models.AccountInfo, error) {
	if m.apiKey == "" || m.apiSecret == "" {
		return nil, fmt.Errorf("API credentials not set")
	}
	
	// Simulate some delay
	time.Sleep(500 * time.Millisecond)
	
	// Generate mock data
	spotBalances := []models.SpotBalance{
		{
			Asset:  "BTC",
			Free:   rand.Float64() * 10,
			Locked: rand.Float64() * 0.5,
		},
		{
			Asset:  "ETH",
			Free:   rand.Float64() * 100,
			Locked: rand.Float64() * 5,
		},
		{
			Asset:  "USDT",
			Free:   rand.Float64() * 10000,
			Locked: rand.Float64() * 1000,
		},
	}
	
	// Calculate totals
	for i := range spotBalances {
		spotBalances[i].Total = spotBalances[i].Free + spotBalances[i].Locked
	}
	
	futuresBalances := []models.FuturesBalance{
		{
			Asset:            "USDT",
			WalletBalance:    rand.Float64() * 5000,
			UnrealizedPNL:    (rand.Float64() - 0.5) * 100,
			MarginBalance:    rand.Float64() * 4000,
			AvailableBalance: rand.Float64() * 3000,
		},
	}
	
	positions := []models.Position{
		{
			Symbol:        "BTCUSDT",
			PositionAmt:   rand.Float64() * 0.1,
			EntryPrice:    50000 + rand.Float64()*10000,
			MarkPrice:     50000 + rand.Float64()*10000,
			UnrealizedPNL: (rand.Float64() - 0.5) * 500,
			PositionSide:  "LONG",
			UpdateTime:    time.Now(),
		},
	}
	
	return &models.AccountInfo{
		SpotBalances:    spotBalances,
		FuturesBalances: futuresBalances,
		Positions:       positions,
	}, nil
}

// CreateOrder creates a mock order
func (m *MockExchange) CreateOrder(ctx context.Context, req *models.NewOrderRequest) (*models.Order, error) {
	if m.apiKey == "" || m.apiSecret == "" {
		return nil, fmt.Errorf("API credentials not set")
	}
	
	// Simulate some delay
	time.Sleep(200 * time.Millisecond)
	
	order := &models.Order{
		Symbol:    req.Symbol,
		OrderID:   fmt.Sprintf("order_%d", time.Now().Unix()),
		Side:      req.Side,
		Type:      req.Type,
		Quantity:  req.Quantity,
		Price:     req.Price,
		Status:    "NEW",
		Time:      time.Now(),
	}
	
	return order, nil
}

// CancelOrder cancels a mock order
func (m *MockExchange) CancelOrder(ctx context.Context, symbol, orderID string) error {
	if m.apiKey == "" || m.apiSecret == "" {
		return fmt.Errorf("API credentials not set")
	}
	
	// Simulate some delay
	time.Sleep(200 * time.Millisecond)
	
	return nil
}

// GetExchangeType returns the exchange type
func (m *MockExchange) GetExchangeType() models.ExchangeType {
	return m.exchangeType
}