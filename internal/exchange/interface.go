package exchange

import (
	"context"
	"github.com/freeeverett/qaroto/internal/models"
)

// Exchange defines the interface for cryptocurrency exchanges
type Exchange interface {
	// SetCredentials sets the API credentials
	SetCredentials(apiKey, apiSecret string)
	
	// GetAccountInfo retrieves account information including balances and positions
	GetAccountInfo(ctx context.Context) (*models.AccountInfo, error)
	
	// CreateOrder creates a new trading order
	CreateOrder(ctx context.Context, req *models.NewOrderRequest) (*models.Order, error)
	
	// CancelOrder cancels an existing order
	CancelOrder(ctx context.Context, symbol, orderID string) error
	
	// GetExchangeType returns the type of exchange
	GetExchangeType() models.ExchangeType
}