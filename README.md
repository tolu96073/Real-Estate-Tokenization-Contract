# 🏠 Real Estate Tokenization Smart Contract

A Clarity smart contract that enables **fractional real estate ownership** through blockchain tokenization. Transform any property into tradeable tokens and earn passive income through dividend distributions! 🚀

## ✨ Features

- 🏘️ **Property Registration** - Create tokenized real estate assets
- 🪙 **Fractional Ownership** - Buy and sell property tokens
- 💰 **Dividend Distribution** - Earn rental income proportional to token holdings  
- 🔄 **Token Transfers** - Trade ownership stakes with other investors
- 📊 **Property Management** - Update valuations and property status
- 💎 **Metadata Support** - Store detailed property information
- 🎯 **Property Auctions** - Competitive bidding system for property sales

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Stacks blockchain and Clarity

### Installation

```bash
git clone <your-repo>
cd real-estate-tokenization-contract
clarinet console
```

## 📖 Usage

### 1. Create a Property 🏗️

```clarity
(contract-call? .real-estate-tokenization-contract create-property 
  "Sunset Villa" 
  "Beautiful 3BR villa with ocean view"
  u1000000  ;; Total value in microSTX
  u1000     ;; Total tokens to mint
  "Miami Beach, FL"
  "Villa"
  u2500     ;; Size in sqft  
  u2020)    ;; Year built
```

### 2. Buy Property Tokens 🛍️

```clarity
(contract-call? .real-estate-tokenization-contract buy-tokens 
  u1        ;; Property ID
  u50)      ;; Number of tokens to buy
```

### 3. Transfer Tokens 📤

```clarity
(contract-call? .real-estate-tokenization-contract transfer-tokens
  u1                    ;; Property ID
  u25                   ;; Token amount
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)  ;; Recipient
```

### 4. Distribute Dividends 💸

```clarity
;; Property owner distributes rental income
(contract-call? .real-estate-tokenization-contract distribute-dividends
  u1        ;; Property ID  
  u50000)   ;; Total dividend amount
```

### 5. Claim Your Dividends 🎉

```clarity
(contract-call? .real-estate-tokenization-contract claim-dividends u1)
```

### 6. Create Property Auction 🎯

```clarity
;; Property owner creates auction for 100 blocks duration
(contract-call? .real-estate-tokenization-contract create-auction 
  u1        ;; Property ID
  u800000   ;; Starting price
  u100)     ;; Duration in blocks
```

### 7. Place Bid on Property 💰

```clarity
(contract-call? .real-estate-tokenization-contract place-bid
  u1        ;; Auction ID
  u900000)  ;; Bid amount
```

### 8. Finalize Auction (after end block) 🏆

```clarity
(contract-call? .real-estate-tokenization-contract finalize-auction u1)
```

## 📊 Read Functions

### Get Property Information
```clarity
(contract-call? .real-estate-tokenization-contract get-property u1)
(contract-call? .real-estate-tokenization-contract get-property-metadata u1)
```

### Check Token Balance
```clarity
(contract-call? .real-estate-tokenization-contract get-token-balance 
  u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Check Claimable Dividends
```clarity
(contract-call? .real-estate-tokenization-contract get-claimable-dividends
  u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Get Auction Information
```clarity
(contract-call? .real-estate-tokenization-contract get-auction u1)
(contract-call? .real-estate-tokenization-contract get-auction-bid u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🏗️ Contract Architecture

### Core Data Structures

- **Properties Map** - Stores property details, valuation, and token information
- **Token Balances Map** - Tracks ownership distribution across holders
- **Property Dividends Map** - Manages dividend pools and distribution rates
- **Claimed Dividends Map** - Records dividend withdrawals by holders
- **Property Auctions Map** - Manages auction lifecycle and bidding data
- **Auction Bids Map** - Tracks individual bidder amounts per auction

### Key Functions

| Function | Description | Access |
|----------|-------------|---------|
| `create-property` | Register new tokenized property | Anyone |
| `buy-tokens` | Purchase fractional ownership | Anyone |
| `transfer-tokens` | Transfer tokens between users | Token holders |
| `distribute-dividends` | Add funds to dividend pool | Property owner |
| `claim-dividends` | Withdraw earned dividends | Token holders |
| `update-property-value` | Adjust property valuation | Property owner |
| `create-auction` | Start competitive property sale | Property owner |
| `place-bid` | Bid on property auction | Anyone |
| `finalize-auction` | Complete sale to highest bidder | Anyone (after end) |

## 🔐 Security Features

- ✅ Owner-only functions for critical operations
- ✅ Balance validation for all token transfers  
- ✅ Active property status checks
- ✅ Dividend calculation accuracy
- ✅ Auction timing and bidding constraints
- ✅ Proper error handling with descriptive codes

## 🧪 Testing

```bash
# Run contract tests
clarinet test

# Check contract deployment
clarinet check

# Start local development environment
clarinet console
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License.

## 🎯 Use Cases

- **Real Estate Investment Trusts (REITs)** 📈
- **Fractional Property Investment** 🏘️
- **Rental Income Distribution** 💰
- **Property Crowdfunding** 👥
- **Real Estate Liquid Markets** 📊
- **Property Exit Strategies via Auctions** 🎯

---

**Ready to tokenize real estate? Start building the future of property investment! 🚀🏠**
