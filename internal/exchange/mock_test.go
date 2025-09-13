package exchange

import (
	"context"
	"testing"
	"github.com/freeeverett/qaroto/internal/models"
)

func TestMockExchange(t *testing.T) {
	exchange := NewMockExchange(models.ExchangeBinance)
	
	if exchange.GetExchangeType() != models.ExchangeBinance {
		t.Errorf("Expected exchange type to be %s, got %s", 
			models.ExchangeBinance, exchange.GetExchangeType())
	}
	
	// Test without credentials
	ctx := context.Background()
	_, err := exchange.GetAccountInfo(ctx)
	if err == nil {
		t.Error("Expected error when getting account info without credentials")
	}
	
	// Set credentials and test
	exchange.SetCredentials("test_key", "test_secret")
	
	accountInfo, err := exchange.GetAccountInfo(ctx)
	if err != nil {
		t.Errorf("Unexpected error: %v", err)
	}
	
	if len(accountInfo.SpotBalances) == 0 {
		t.Error("Expected spot balances to be returned")
	}
	
	// Test order creation
	orderReq := &models.NewOrderRequest{
		Symbol:   "BTCUSDT",
		Side:     models.OrderSideBuy,
		Type:     models.OrderTypeLimit,
		Quantity: 0.001,
		Price:    50000.0,
	}
	
	order, err := exchange.CreateOrder(ctx, orderReq)
	if err != nil {
		t.Errorf("Unexpected error creating order: %v", err)
	}
	
	if order.Symbol != "BTCUSDT" {
		t.Errorf("Expected order symbol to be 'BTCUSDT', got %s", order.Symbol)
	}
	
	// Test order cancellation
	err = exchange.CancelOrder(ctx, "BTCUSDT", order.OrderID)
	if err != nil {
		t.Errorf("Unexpected error canceling order: %v", err)
	}
}