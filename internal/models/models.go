package models

import (
	"time"
)

// ExchangeType represents different supported exchanges
type ExchangeType string

const (
	ExchangeBinance ExchangeType = "binance"
	ExchangeOKX     ExchangeType = "okx"
)

// APICredentials holds the API key and secret
type APICredentials struct {
	APIKey    string
	APISecret string
	Exchange  ExchangeType
}

// SpotBalance represents a spot account balance
type SpotBalance struct {
	Asset     string  `json:"asset"`
	Free      float64 `json:"free,string"`
	Locked    float64 `json:"locked,string"`
	Total     float64 `json:"total"`
}

// FuturesBalance represents a futures account balance
type FuturesBalance struct {
	Asset           string  `json:"asset"`
	WalletBalance   float64 `json:"walletBalance,string"`
	UnrealizedPNL   float64 `json:"unrealizedPnl,string"`
	MarginBalance   float64 `json:"marginBalance,string"`
	AvailableBalance float64 `json:"availableBalance,string"`
}

// Position represents a futures position
type Position struct {
	Symbol           string    `json:"symbol"`
	PositionAmt      float64   `json:"positionAmt,string"`
	EntryPrice       float64   `json:"entryPrice,string"`
	MarkPrice        float64   `json:"markPrice,string"`
	UnrealizedPNL    float64   `json:"unRealizedProfit,string"`
	PositionSide     string    `json:"positionSide"`
	UpdateTime       time.Time `json:"updateTime"`
}

// OrderSide represents buy or sell
type OrderSide string

const (
	OrderSideBuy  OrderSide = "BUY"
	OrderSideSell OrderSide = "SELL"
)

// OrderType represents different order types
type OrderType string

const (
	OrderTypeMarket OrderType = "MARKET"
	OrderTypeLimit  OrderType = "LIMIT"
)

// Order represents a trading order
type Order struct {
	Symbol    string    `json:"symbol"`
	OrderID   string    `json:"orderId"`
	Side      OrderSide `json:"side"`
	Type      OrderType `json:"type"`
	Quantity  float64   `json:"origQty,string"`
	Price     float64   `json:"price,string"`
	Status    string    `json:"status"`
	Time      time.Time `json:"time"`
}

// NewOrderRequest represents a request to create a new order
type NewOrderRequest struct {
	Symbol    string
	Side      OrderSide
	Type      OrderType
	Quantity  float64
	Price     float64 // Only for limit orders
}

// AccountInfo aggregates all account information
type AccountInfo struct {
	SpotBalances    []SpotBalance
	FuturesBalances []FuturesBalance
	Positions       []Position
}