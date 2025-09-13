package models

import (
	"testing"
)

func TestAPICredentials(t *testing.T) {
	creds := APICredentials{
		APIKey:    "test_key",
		APISecret: "test_secret",
		Exchange:  ExchangeBinance,
	}
	
	if creds.APIKey != "test_key" {
		t.Errorf("Expected API key to be 'test_key', got %s", creds.APIKey)
	}
	
	if creds.Exchange != ExchangeBinance {
		t.Errorf("Expected exchange to be %s, got %s", ExchangeBinance, creds.Exchange)
	}
}

func TestNewOrderRequest(t *testing.T) {
	req := NewOrderRequest{
		Symbol:   "BTCUSDT",
		Side:     OrderSideBuy,
		Type:     OrderTypeLimit,
		Quantity: 0.001,
		Price:    50000.0,
	}
	
	if req.Symbol != "BTCUSDT" {
		t.Errorf("Expected symbol to be 'BTCUSDT', got %s", req.Symbol)
	}
	
	if req.Side != OrderSideBuy {
		t.Errorf("Expected side to be %s, got %s", OrderSideBuy, req.Side)
	}
}