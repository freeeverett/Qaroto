# Qaroto - Binance API Tool for iPad

A powerful iPad application for querying Binance trading account information through the official Binance API.

## Features

- **Secure API Key Management**: Manual input of API key and secret with secure text fields
- **Multiple Account Views**: 
  - Spot Balance
  - Spot Pending Orders
  - Contract Account Balance
  - Contract Positions
  - Contract Pending Orders
- **Memory Security**: Clear credentials and data on demand
- **iPad Optimized**: Designed specifically for iPad with landscape and portrait support

## Requirements

- iOS 15.0+
- iPad (optimized for iPad interface)
- Valid Binance API credentials with appropriate permissions

## Setup

1. Open `qaroto.xcodeproj` in Xcode
2. Select an iPad simulator or connected iPad device
3. Build and run the application

## Usage

1. **Enter Credentials**: Input your Binance API Key and Secret in the secure text fields at the top
2. **Refresh Data**: Tap "Refresh All Data" to query all account information
3. **Browse Data**: Use the tab interface to view different types of account data:
   - **Spot Balance**: View available and locked balances for all assets
   - **Spot Orders**: See all pending spot trading orders
   - **Contract Balance**: Check futures account balances
   - **Contract Positions**: Monitor active futures positions with PnL
   - **Contract Orders**: Review pending futures orders
4. **Clear Data**: Use "Clear Credentials" to remove all sensitive information from memory

## Security Features

- API credentials are stored only in memory during app session
- Secure text fields prevent credential exposure
- One-tap credential clearing removes all sensitive data
- No persistent storage of API keys or secrets

## API Permissions Required

Your Binance API key needs the following permissions:
- **Spot Account Read**: For spot balances and orders
- **Futures Account Read**: For contract balances, positions, and orders

## Project Structure

```
qaroto/
├── qaroToApp.swift          # Main app entry point
├── ContentView.swift        # Main UI with tab interface
├── Models.swift            # Data models for Binance API responses
├── BinanceAPI.swift        # API client and networking layer
├── Info.plist             # App configuration
└── Assets.xcassets/        # App icons and assets
```

## Technical Notes

- Built with SwiftUI for modern, responsive UI
- Uses async/await for efficient API calls
- Implements proper HMAC-SHA256 signing for Binance API authentication
- Optimized for iPad with adaptive layouts
- Supports all iPad orientations

## Safety Warning

- Never share your API credentials
- Use API keys with read-only permissions when possible
- Always clear credentials when finished using the app
- This app does not store credentials persistently for security

## License

MIT License - see LICENSE file for details