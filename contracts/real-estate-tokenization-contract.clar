(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-tokens (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-property-inactive (err u105))
(define-constant err-no-tokens-to-claim (err u106))
(define-constant err-auction-not-found (err u107))
(define-constant err-auction-ended (err u108))
(define-constant err-auction-active (err u109))
(define-constant err-bid-too-low (err u110))
(define-constant err-not-highest-bidder (err u111))
(define-constant err-proposal-not-found (err u112))
(define-constant err-voting-ended (err u113))
(define-constant err-voting-active (err u114))
(define-constant err-already-voted (err u115))
(define-constant err-quorum-not-met (err u116))
(define-constant err-proposal-rejected (err u117))
(define-constant err-insufficient-stake (err u118))
(define-constant err-insufficient-allowance (err u119))
(define-constant err-not-allowed (err u120))

(define-data-var property-counter uint u0)
(define-data-var auction-counter uint u0)
(define-data-var proposal-counter uint u0)

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

(define-map token-allowances
  { property-id: uint, owner: principal, spender: principal }
  { amount: uint }
)

(define-map property-allowlist-enabled
  { property-id: uint }
  { enabled: bool }
)

(define-map property-allowlist
  { property-id: uint, user: principal }
  { allowed: bool }
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

(define-map property-auctions
  { auction-id: uint }
  {
    property-id: uint,
    seller: principal,
    starting-price: uint,
    current-bid: uint,
    highest-bidder: (optional principal),
    end-block: uint,
    active: bool
  }
)

(define-map auction-bids
  { auction-id: uint, bidder: principal }
  { bid-amount: uint }
)

(define-map governance-proposals
  { proposal-id: uint }
  {
    property-id: uint,
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 300),
    proposal-type: (string-ascii 20),
    amount-requested: uint,
    yes-votes: uint,
    no-votes: uint,
    end-block: uint,
    executed: bool,
    active: bool
  }
)

(define-map proposal-votes
  { proposal-id: uint, voter: principal }
  { vote-weight: uint, vote-for: bool }
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

(define-read-only (get-allowance (property-id uint) (owner principal) (spender principal))
  (default-to u0 (get amount (map-get? token-allowances { property-id: property-id, owner: owner, spender: spender })))
)

(define-read-only (get-allowlist-enabled (property-id uint))
  (default-to false (get enabled (map-get? property-allowlist-enabled { property-id: property-id })))
)

(define-read-only (is-allowed-buyer (property-id uint) (user principal))
  (default-to false (get allowed (map-get? property-allowlist { property-id: property-id, user: user })))
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

(define-read-only (get-auction (auction-id uint))
  (map-get? property-auctions { auction-id: auction-id })
)

(define-read-only (get-auction-bid (auction-id uint) (bidder principal))
  (default-to u0 (get bid-amount (map-get? auction-bids { auction-id: auction-id, bidder: bidder })))
)

(define-read-only (get-auction-counter)
  (var-get auction-counter)
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? governance-proposals { proposal-id: proposal-id })
)

(define-read-only (get-proposal-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (get-proposal-vote proposal-id voter))
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
    (asserts! (> (len name) u0) err-invalid-amount)
    (asserts! (> (len description) u0) err-invalid-amount)
    (asserts! (> (len location) u0) err-invalid-amount)
    (asserts! (> (len property-type) u0) err-invalid-amount)
    (asserts! (> size-sqft u0) err-invalid-amount)
    (asserts! (> year-built u0) err-invalid-amount)
    
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
    (allowlist-enabled (default-to false (get enabled (map-get? property-allowlist-enabled { property-id: property-id }))))
    (is-allowed (default-to false (get allowed (map-get? property-allowlist { property-id: property-id, user: tx-sender }))))
  )
    (asserts! (get active property-info) err-property-inactive)
    (asserts! (> token-amount u0) err-invalid-amount)
    (asserts! (>= (get available-tokens property-info) token-amount) err-insufficient-tokens)
    (asserts! (or (not allowlist-enabled) is-allowed) err-not-allowed)
    
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
    (asserts! (not (is-eq recipient tx-sender)) err-invalid-amount)
    
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

(define-public (approve-allowance (property-id uint) (spender principal) (amount uint))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (not (is-eq spender tx-sender)) err-invalid-amount)
    (map-set token-allowances
      { property-id: property-id, owner: tx-sender, spender: spender }
      { amount: amount }
    )
    (ok amount)
  )
)

(define-public (transfer-from (property-id uint) (owner principal) (recipient principal) (amount uint))
  (let (
    (allowance (get-allowance property-id owner tx-sender))
    (owner-balance (get-token-balance property-id owner))
    (recipient-balance (get-token-balance property-id recipient))
  )
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (>= owner-balance amount) err-insufficient-tokens)
    (asserts! (>= allowance amount) err-insufficient-allowance)
    (asserts! (not (is-eq recipient owner)) err-invalid-amount)
    
    (map-set token-balances
      { property-id: property-id, holder: owner }
      { balance: (- owner-balance amount) }
    )
    
    (map-set token-balances
      { property-id: property-id, holder: recipient }
      { balance: (+ recipient-balance amount) }
    )
    
    (map-set token-allowances
      { property-id: property-id, owner: owner, spender: tx-sender }
      { amount: (- allowance amount) }
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

(define-public (set-allowlist-enabled (property-id uint) (enabled bool))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    (map-set property-allowlist-enabled
      { property-id: property-id }
      { enabled: enabled }
    )
    (ok enabled)
  )
)

(define-public (set-allowlist-entry (property-id uint) (user principal) (allowed bool))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    (map-set property-allowlist
      { property-id: property-id, user: user }
      { allowed: allowed }
    )
    (ok allowed)
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

(define-public (create-auction (property-id uint) (starting-price uint) (duration uint))
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
    (auction-id (+ (var-get auction-counter) u1))
    (end-block (+ stacks-block-height duration))
  )
    (asserts! (is-eq tx-sender (get owner property-info)) err-unauthorized)
    (asserts! (> starting-price u0) err-invalid-amount)
    (asserts! (> duration u0) err-invalid-amount)
    (asserts! (get active property-info) err-property-inactive)
    
    (map-set property-auctions
      { auction-id: auction-id }
      {
        property-id: property-id,
        seller: tx-sender,
        starting-price: starting-price,
        current-bid: u0,
        highest-bidder: none,
        end-block: end-block,
        active: true
      }
    )
    
    (var-set auction-counter auction-id)
    (ok auction-id)
  )
)

(define-public (place-bid (auction-id uint) (bid-amount uint))
  (let (
    (auction-info (unwrap! (get-auction auction-id) err-auction-not-found))
    (previous-bid (get-auction-bid auction-id tx-sender))
    (total-bid (+ previous-bid bid-amount))
  )
    (asserts! (get active auction-info) err-auction-ended)
    (asserts! (<= stacks-block-height (get end-block auction-info)) err-auction-ended)
    (asserts! (> bid-amount u0) err-invalid-amount)
    (asserts! (> total-bid (get current-bid auction-info)) err-bid-too-low)
    (asserts! (>= total-bid (get starting-price auction-info)) err-bid-too-low)
    
    (try! (stx-transfer? bid-amount tx-sender (as-contract tx-sender)))
    
    (map-set auction-bids
      { auction-id: auction-id, bidder: tx-sender }
      { bid-amount: total-bid }
    )
    
    (map-set property-auctions
      { auction-id: auction-id }
      (merge auction-info {
        current-bid: total-bid,
        highest-bidder: (some tx-sender)
      })
    )
    
    (ok total-bid)
  )
)

(define-public (finalize-auction (auction-id uint))
  (let (
    (auction-info (unwrap! (get-auction auction-id) err-auction-not-found))
    (property-info (unwrap! (get-property (get property-id auction-info)) err-not-found))
    (highest-bidder-principal (unwrap! (get highest-bidder auction-info) err-not-found))
  )
    (asserts! (get active auction-info) err-auction-ended)
    (asserts! (> stacks-block-height (get end-block auction-info)) err-auction-active)
    (asserts! (> (get current-bid auction-info) u0) err-not-found)
    
    (try! (as-contract (stx-transfer? (get current-bid auction-info) (as-contract tx-sender) (get seller auction-info))))
    
    (map-set properties
      { property-id: (get property-id auction-info) }
      (merge property-info { owner: highest-bidder-principal })
    )
    
    (map-set property-auctions
      { auction-id: auction-id }
      (merge auction-info { active: false })
    )
    
    (ok (get current-bid auction-info))
  )
)

(define-public (withdraw-bid (auction-id uint))
  (let (
    (auction-info (unwrap! (get-auction auction-id) err-auction-not-found))
    (bidder-bid (get-auction-bid auction-id tx-sender))
    (is-highest-bidder (is-eq (some tx-sender) (get highest-bidder auction-info)))
  )
    (asserts! (> bidder-bid u0) err-not-found)
    (asserts! (or (not (get active auction-info)) (not is-highest-bidder)) err-not-highest-bidder)
    
    (try! (as-contract (stx-transfer? bidder-bid (as-contract tx-sender) tx-sender)))
    
    (map-delete auction-bids { auction-id: auction-id, bidder: tx-sender })
    
    (ok bidder-bid)
  )
)

(define-public (cancel-auction (auction-id uint))
  (let (
    (auction-info (unwrap! (get-auction auction-id) err-auction-not-found))
  )
    (asserts! (is-eq tx-sender (get seller auction-info)) err-unauthorized)
    (asserts! (get active auction-info) err-auction-ended)
    (asserts! (is-eq (get current-bid auction-info) u0) err-auction-active)
    
    (map-set property-auctions
      { auction-id: auction-id }
      (merge auction-info { active: false })
    )
    
    (ok auction-id)
  )
)

(define-public (create-proposal 
  (property-id uint)
  (title (string-ascii 100))
  (description (string-ascii 300))
  (proposal-type (string-ascii 20))
  (amount-requested uint)
  (voting-duration uint)
)
  (let (
    (property-info (unwrap! (get-property property-id) err-not-found))
    (proposer-balance (get-token-balance property-id tx-sender))
    (min-stake (/ (get total-tokens property-info) u100))
    (proposal-id (+ (var-get proposal-counter) u1))
    (end-block (+ stacks-block-height voting-duration))
  )
    (asserts! (>= proposer-balance min-stake) err-insufficient-stake)
    (asserts! (> voting-duration u0) err-invalid-amount)
    (asserts! (> (len title) u0) err-invalid-amount)
    (asserts! (> (len description) u0) err-invalid-amount)
    (asserts! (> (len proposal-type) u0) err-invalid-amount)
    (asserts! (<= amount-requested (get total-value property-info)) err-invalid-amount)
    
    (map-set governance-proposals
      { proposal-id: proposal-id }
      {
        property-id: property-id,
        proposer: tx-sender,
        title: title,
        description: description,
        proposal-type: proposal-type,
        amount-requested: amount-requested,
        yes-votes: u0,
        no-votes: u0,
        end-block: end-block,
        executed: false,
        active: true
      }
    )
    
    (var-set proposal-counter proposal-id)
    (ok proposal-id)
  )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let (
    (proposal-info (unwrap! (get-proposal proposal-id) err-proposal-not-found))
    (voter-tokens (get-token-balance (get property-id proposal-info) tx-sender))
    (current-yes-votes (get yes-votes proposal-info))
    (current-no-votes (get no-votes proposal-info))
  )
    (asserts! (get active proposal-info) err-voting-ended)
    (asserts! (<= stacks-block-height (get end-block proposal-info)) err-voting-ended)
    (asserts! (> voter-tokens u0) err-insufficient-tokens)
    (asserts! (not (has-voted proposal-id tx-sender)) err-already-voted)
    
    (map-set proposal-votes
      { proposal-id: proposal-id, voter: tx-sender }
      { vote-weight: voter-tokens, vote-for: vote-for }
    )
    
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal-info {
        yes-votes: (if vote-for (+ current-yes-votes voter-tokens) current-yes-votes),
        no-votes: (if vote-for current-no-votes (+ current-no-votes voter-tokens))
      })
    )
    
    (ok voter-tokens)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal-info (unwrap! (get-proposal proposal-id) err-proposal-not-found))
    (property-info (unwrap! (get-property (get property-id proposal-info)) err-not-found))
    (total-votes (+ (get yes-votes proposal-info) (get no-votes proposal-info)))
    (total-tokens (get total-tokens property-info))
    (quorum-threshold (/ total-tokens u2))
    (vote-passed (> (get yes-votes proposal-info) (get no-votes proposal-info)))
  )
    (asserts! (get active proposal-info) err-voting-ended)
    (asserts! (> stacks-block-height (get end-block proposal-info)) err-voting-active)
    (asserts! (not (get executed proposal-info)) err-already-exists)
    (asserts! (>= total-votes quorum-threshold) err-quorum-not-met)
    (asserts! vote-passed err-proposal-rejected)
    
    (if (> (get amount-requested proposal-info) u0)
      (try! (as-contract (stx-transfer? (get amount-requested proposal-info) (as-contract tx-sender) (get proposer proposal-info))))
      true
    )
    
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal-info { executed: true, active: false })
    )
    
    (ok proposal-id)
  )
)

(define-public (cancel-proposal (proposal-id uint))
  (let (
    (proposal-info (unwrap! (get-proposal proposal-id) err-proposal-not-found))
  )
    (asserts! (is-eq tx-sender (get proposer proposal-info)) err-unauthorized)
    (asserts! (get active proposal-info) err-voting-ended)
    (asserts! (is-eq (+ (get yes-votes proposal-info) (get no-votes proposal-info)) u0) err-voting-active)
    
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal-info { active: false })
    )
    
    (ok proposal-id)
  )
)

(define-read-only (get-proposal-status (proposal-id uint))
  (let (
    (proposal-info (get-proposal proposal-id))
  )
    (match proposal-info
      proposal-data (ok {
        total-votes: (+ (get yes-votes proposal-data) (get no-votes proposal-data)),
        yes-percentage: (if (> (+ (get yes-votes proposal-data) (get no-votes proposal-data)) u0)
                           (/ (* (get yes-votes proposal-data) u100) (+ (get yes-votes proposal-data) (get no-votes proposal-data)))
                           u0),
        is-passing: (> (get yes-votes proposal-data) (get no-votes proposal-data)),
        time-remaining: (if (> (get end-block proposal-data) stacks-block-height)
                          (- (get end-block proposal-data) stacks-block-height)
                          u0)
      })
      err-proposal-not-found
    )
  )
)
