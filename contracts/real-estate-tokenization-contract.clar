(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-tokens (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-property-inactive (err u105))
(define-constant err-no-tokens-to-claim (err u106))

(define-data-var property-counter uint u0)

(define-map properties
  { property-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    total-value: uint,
    total-tokens: uint,
    available-tokens: uint,
    price-per-token: uint,
    owner: principal,
    active: bool,
    created-at: uint
  }
)

(define-map token-balances
  { property-id: uint, holder: principal }
  { balance: uint }
)

(define-map property-dividends
  { property-id: uint }
  { 
    total-dividends: uint,
    dividends-per-token: uint,
    last-distribution: uint
  }
)

(define-map claimed-dividends
  { property-id: uint, holder: principal }
  { claimed-amount: uint }
)

(define-map property-metadata
  { property-id: uint }
  {
    location: (string-ascii 100),
    property-type: (string-ascii 20),
    size-sqft: uint,
    year-built: uint
  }
)

(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

(define-read-only (get-property-metadata (property-id uint))
  (map-get? property-metadata { property-id: property-id })
)

(define-read-only (get-token-balance (property-id uint) (holder principal))
  (default-to u0 (get balance (map-get? token-balances { property-id: property-id, holder: holder })))
)

(define-read-only (get-property-dividends (property-id uint))
  (map-get? property-dividends { property-id: property-id })
)

(define-read-only (get-claimed-dividends (property-id uint) (holder principal))
  (default-to u0 (get claimed-amount (map-get? claimed-dividends { property-id: property-id, holder: holder })))
)

(define-read-only (get-property-counter)
  (var-get property-counter)
)

(define-read-only (calculate-dividend-share (property-id uint) (holder principal))
  (let (
    (token-balance (get-token-balance property-id holder))
    (dividends-info (get-property-dividends property-id))
  )
    (match dividends-info
      dividend-data (if (> token-balance u0)
                     (* token-balance (get dividends-per-token dividend-data))
                     u0)
      u0
    )
  )
)

(define-public (create-property 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (total-value uint)
  (total-tokens uint)
  (location (string-ascii 100))
  (property-type (string-ascii 20))
  (size-sqft uint)
  (year-built uint)
)
  (let (
    (property-id (+ (var-get property-counter) u1))
    (price-per-token (/ total-value total-tokens))
  )
    (asserts! (> total-value u0) err-invalid-amount)
    (asserts! (> total-tokens u0) err-invalid-amount)
    
    (map-set properties 
      { property-id: property-id }
      {
        name: name,
        description: description,
        total-value: total-value,
        total-tokens: total-tokens,
        available-tokens: total-tokens,
        price-per-token: price-per-token,
        owner: tx-sender,
        active: true,
        created-at: stacks-block-height
      }
    )
    
    (map-set property-metadata
      { property-id: property-id }
      {
        location: location,
        property-type: property-type,
        size-sqft: size-sqft,
        year-built: year-built
      }
    )
    
    (map-set property-dividends
      { property-id: property-id }
      {
        total-dividends: u0,
        dividends-per-token: u0,
        last-distribution: u0
      }
    )
    
    (var-set property-counter property-id)
    (ok property-id)
  )
)

(define-public (buy-tokens (property-id uint) (token-amount uint))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
    (price-per-token (get price-per-token property-info))
    (total-cost (* token-amount price-per-token))
    (current-balance (get-token-balance property-id tx-sender))
  )
    (asserts! (get active property-info) err-property-inactive)
    (asserts! (> token-amount u0) err-invalid-amount)
    (asserts! (>= (get available-tokens property-info) token-amount) err-insufficient-tokens)
    
    (try! (stx-transfer? total-cost tx-sender (get owner property-info)))
    
    (map-set token-balances
      { property-id: property-id, holder: tx-sender }
      { balance: (+ current-balance token-amount) }
    )
    
    (map-set properties
      { property-id: property-id }
      (merge property-info { available-tokens: (- (get available-tokens property-info) token-amount) })
    )
    
    (ok token-amount)
  )
)

(define-public (transfer-tokens (property-id uint) (amount uint) (recipient principal))
  (let (
    (sender-balance (get-token-balance property-id tx-sender))
    (recipient-balance (get-token-balance property-id recipient))
  )
    (asserts! (>= sender-balance amount) err-insufficient-tokens)
    (asserts! (> amount u0) err-invalid-amount)
    
    (map-set token-balances
      { property-id: property-id, holder: tx-sender }
      { balance: (- sender-balance amount) }
    )
    
    (map-set token-balances
      { property-id: property-id, holder: recipient }
      { balance: (+ recipient-balance amount) }
    )
    
    (ok amount)
  )
)

(define-public (distribute-dividends (property-id uint) (total-dividend-amount uint))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
    (current-dividends (unwrap! (get-property-dividends property-id) err-not-found))
    (dividends-per-token (/ total-dividend-amount (get total-tokens property-info)))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    (asserts! (> total-dividend-amount u0) err-invalid-amount)
    
    (map-set property-dividends
      { property-id: property-id }
      {
        total-dividends: (+ (get total-dividends current-dividends) total-dividend-amount),
        dividends-per-token: (+ (get dividends-per-token current-dividends) dividends-per-token),
        last-distribution: stacks-block-height
      }
    )
    
    (ok total-dividend-amount)
  )
)

(define-public (claim-dividends (property-id uint))
  (let (
    (token-balance (get-token-balance property-id tx-sender))
    (total-dividend-share (calculate-dividend-share property-id tx-sender))
    (already-claimed (get-claimed-dividends property-id tx-sender))
    (claimable-amount (- total-dividend-share already-claimed))
  )
    (asserts! (> token-balance u0) err-insufficient-tokens)
    (asserts! (> claimable-amount u0) err-no-tokens-to-claim)
    
    (try! (as-contract (stx-transfer? claimable-amount (as-contract tx-sender) tx-sender)))
    
    (map-set claimed-dividends
      { property-id: property-id, holder: tx-sender }
      { claimed-amount: total-dividend-share }
    )
    
    (ok claimable-amount)
  )
)

(define-public (update-property-status (property-id uint) (active bool))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    
    (map-set properties
      { property-id: property-id }
      (merge property-info { active: active })
    )
    
    (ok active)
  )
)

(define-public (update-property-value (property-id uint) (new-value uint))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
    (new-price-per-token (/ new-value (get total-tokens property-info)))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    (asserts! (> new-value u0) err-invalid-amount)
    
    (map-set properties
      { property-id: property-id }
      (merge property-info { 
        total-value: new-value,
        price-per-token: new-price-per-token
      })
    )
    
    (ok new-value)
  )
)

(define-public (get-claimable-dividends (property-id uint) (holder principal))
  (let (
    (total-dividend-share (calculate-dividend-share property-id holder))
    (already-claimed (get-claimed-dividends property-id holder))
  )
    (ok (- total-dividend-share already-claimed))
  )
)

(define-read-only (get-property-owners (property-id uint))
  (let (
    (property-info (get-property property-id))
  )
    (match property-info
      prop-data (ok (get owner prop-data))
      err-not-found
    )
  )
)
