# Qaroto - Cryptocurrency Trading Interface

A Go-based desktop application for cryptocurrency trading with Binance and OKX support, built using the [Fyne](https://fyne.io) framework for cross-platform compatibility.

## Features

### Security & API Management
- **Manual API Key Entry**: API keys and secrets must be entered manually by users
- **No Local Storage**: Credentials are never cached or stored locally for maximum security
- **Exchange Support**: Compatible with both Binance and OKX exchanges

### Account Management
- **Spot Account Balances**: View all spot trading balances with free, locked, and total amounts
- **Futures Margin Balances**: Monitor futures account balances including wallet balance, unrealized PNL, margin balance, and available balance
- **Position Details**: Track all open futures positions with entry price, mark price, unrealized PNL, and position side

### Trading Features
- **Order Creation**: Create market and limit orders with customizable parameters
- **Order Cancellation**: Cancel existing orders (functionality implemented, UI can be extended)
- **Real-time Updates**: Refresh account information and positions on demand

### Platform Compatibility
- **Cross-Platform**: Compatible with iPad and macOS (and other platforms supported by Fyne)
- **Responsive UI**: Clean, tabbed interface for easy navigation between different account views

## Getting Started

### Prerequisites
- Go 1.25.1 or later
- Platform-specific GUI dependencies:
  - Linux: `libgl1-mesa-dev xorg-dev`
  - macOS: Xcode command line tools
  - Windows: No additional dependencies

### Installation

1. Clone the repository:
```bash
git clone https://github.com/freeeverett/qaroto.git
cd qaroto
```

2. Install dependencies:
```bash
go mod tidy
```

3. Build the application:
```bash
go build ./cmd/main
```

4. Run the application:
```bash
./main  # Linux/macOS
main.exe  # Windows
```

### Usage

1. **Connect to Exchange**:
   - Select your exchange (Binance or OKX)
   - Enter your API Key and API Secret
   - Click "Connect"

2. **View Account Information**:
   - Click "Refresh Account Info" to load your account data
   - Navigate between tabs to view:
     - Spot Balances
     - Futures Balances
     - Open Positions

3. **Create Orders**:
   - Enter the trading symbol (e.g., BTCUSDT)
   - Select Buy or Sell
   - Choose Market or Limit order type
   - Enter quantity and price (for limit orders)
   - Click "Create Order"

## Development

### Architecture

The application follows a clean architecture pattern:

- `internal/models/`: Data structures and types
- `internal/exchange/`: Exchange interface and implementations
- `internal/ui/`: User interface components
- `cmd/main/`: Application entry point

### Testing

Run tests with:
```bash
go test ./...
```

### Mock Implementation

The current implementation uses mock exchanges for development and testing. To integrate with real exchanges:

1. Implement the `Exchange` interface for each exchange
2. Add proper API clients for Binance and OKX
3. Handle authentication and rate limiting
4. Implement error handling for network issues

## Security Notes

- API credentials are only stored in memory during the application session
- No credentials are persisted to disk or configuration files
- Users must re-enter credentials each time the application starts
- Consider using environment variables for development/testing

## License

This project is licensed under the terms specified in the repository.
