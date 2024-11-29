;; Real Estate Community Token (RECT) Contract
;; Enhanced with additional error checks

(define-fungible-token real-estate-community-token)

;; Additional error constants
(define-constant err-zero-value (err u106))
(define-constant err-overflow (err u107))
(define-constant err-voting-ended (err u108))
(define-constant err-no-voting-power (err u109))
(define-constant err-invalid-period (err u110))
(define-constant err-invalid-supply (err u111))
(define-constant err-not-owner (err u112))
(define-constant contract-owner tx-sender)
(define-constant err-property-exists (err u113))
(define-constant err-property-not-found (err u114))
(define-constant err-unauthorized (err u115))
(define-constant err-invalid-vote (err u116))


(define-map block-heights 
  { 
    contract-identifier: principal 
  }
  {
    current-block: uint,
    last-updated-block: uint
  }
)

;; Standalone block height tracking
(define-data-var current-block-height uint u0)

;; Update block height
(define-public (increment-block-height)
  (begin
    (var-set current-block-height (+ (var-get current-block-height) u1))
    (ok true)
  )
)

;; Read current block height
(define-read-only (get-block-height)
  (var-get current-block-height)
)

;; Check if specific blocks have passed
(define-read-only (blocks-passed (block-count uint))
  (>= (get-block-height) block-count)
)

;; Initialize block height tracking for the contract
(define-public (initialize-block-tracking)
  (begin
    (map-set block-heights 
      { contract-identifier: tx-sender }
      {
        current-block: (var-get current-block-height),
        last-updated-block: (var-get current-block-height)
      }
    )
    (ok true)
  )
)

;; Update block height
(define-public (update-contract-block-height)
  (let 
    (
      (current-tracking (unwrap! 
        (map-get? block-heights { contract-identifier: tx-sender }) 
        (err u404))
      )
      (stored-last-block (get last-updated-block current-tracking))
      (current-blockchain-height (var-get current-block-height))
    )
    (begin
      ;; Only update if blockchain height has changed
      (if (> current-blockchain-height stored-last-block)
          (map-set block-heights 
            { contract-identifier: tx-sender }
            {
              current-block: (- current-blockchain-height stored-last-block),
              last-updated-block: current-blockchain-height
            }
          )
          ;; If no change, keep existing values
          (map-set block-heights 
            { contract-identifier: tx-sender }
            current-tracking
          )
      )
      (ok true)
    )
  )
)

;; Retrieve current tracked block height
(define-read-only (get-contract-block-height)
  (let 
    (
      (current-tracking 
        (default-to 
          { current-block: u0, last-updated-block: u0 }
          (map-get? block-heights { contract-identifier: tx-sender })
        )
      )
    )
    (get current-block current-tracking)
  )
)

;; Helper function to check for numeric overflow
(define-private (check-add (a uint) (b uint))
  (let
    (
      (sum (+ a b))
    )
    (asserts! (>= sum a) err-overflow)
    (ok sum)
  )
)

(define-map properties
  { property-id: uint }
  {
    total-value: uint,
    rental-income: uint,
    management-wallet: principal,
    token-supply: uint,
    is-active: bool
  }
)


;; Create a new property token with enhanced validation
(define-public (create-property-token 
  (property-id uint)
  (total-value uint)
  (initial-supply uint)
  (management-wallet principal)
)
  (begin
    ;; Existing owner check
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    
    ;; New validation checks
    (asserts! (> total-value u0) err-zero-value)
    (asserts! (> initial-supply u0) err-invalid-supply)
    (asserts! (>= total-value initial-supply) err-invalid-supply)
    
    ;; Check property doesn't exist
    (asserts! 
      (is-none (map-get? properties { property-id: property-id }))
      err-property-exists
    )
    
    ;; Create property with validated values
    (map-set properties 
      { property-id: property-id }
      {
        total-value: total-value,
        rental-income: u0,
        management-wallet: management-wallet,
        token-supply: initial-supply,
        is-active: true
      }
    )
    
    ;; Safe token minting
    (match (ft-mint? real-estate-community-token initial-supply tx-sender)
      success (ok true)
      error (err error)
    )
  )
)

(define-map voting-power
    { property-id: uint, voter: principal }
    { token-balance: uint }
)


(define-map property-votes
  { 
    property-id: uint, 
    proposal-id: uint 
  }
  {
    yes-votes: uint,
    no-votes: uint,
    proposal-description: (string-utf8 500),
    voting-deadline: uint
  }
)