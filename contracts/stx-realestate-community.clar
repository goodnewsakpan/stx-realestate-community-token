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


;; Enhanced purchase tokens function
(define-public (purchase-tokens 
  (property-id uint)
  (token-amount uint)
)
  (let 
    (
      (property (unwrap! 
        (map-get? properties { property-id: property-id }) 
        err-property-not-found
      ))
      (current-supply (get token-supply property))
    )
    ;; Enhanced validation
    (asserts! (> token-amount u0) err-zero-value)
    (asserts! (get is-active property) err-unauthorized)
    
    ;; Check if purchase would exceed total supply
    (asserts! (<= token-amount current-supply) err-invalid-supply)
    
    ;; Safe token transfer
    (match (ft-transfer? 
      real-estate-community-token 
      token-amount 
      tx-sender 
      (get management-wallet property)
    )
      success (begin
        ;; Update voting power safely
        (map-set voting-power 
          { 
            property-id: property-id, 
            voter: tx-sender 
          }
          {
            token-balance: token-amount
          }
        )
        (ok true)
      )
      error (err error)
    )
  )
)

;; Enhanced proposal submission
(define-public (submit-proposal
  (property-id uint)
  (description (string-utf8 500))
  (voting-period uint)
)
  (let 
    (
      (property (unwrap! 
        (map-get? properties { property-id: property-id }) 
        err-property-not-found
      ))
      (proposal-id (var-get current-block-height))
    )
    ;; Enhanced validation
    (asserts! (get is-active property) err-unauthorized)
    (asserts! (> voting-period u0) err-invalid-period)
    
    ;; Ensure proposer has voting power
    (asserts! 
      (> 
        (get token-balance 
          (default-to 
            { token-balance: u0 }
            (map-get? voting-power { property-id: property-id, voter: tx-sender })
          )
        ) 
        u0
      ) 
      err-no-voting-power
    )
    
    ;; Create proposal with safe arithmetic
    (let
      (
        (deadline (unwrap! (check-add (var-get current-block-height) voting-period) err-overflow))
      )
      (map-set property-votes
        { 
          property-id: property-id, 
          proposal-id: proposal-id 
        }
        {
          yes-votes: u0,
          no-votes: u0,
          proposal-description: description,
          voting-deadline: deadline
        }
      )
      
      (ok proposal-id)
    )
  )
)


;; Vote on a property management proposal
(define-public (vote-on-proposal
  (property-id uint)
  (proposal-id uint)
  (vote bool)
)
  (let 
    (
      (proposal (unwrap! 
        (map-get? property-votes 
          { 
            property-id: property-id, 
            proposal-id: proposal-id 
          }
        ) 
        err-invalid-vote
      ))
      (voter-power (default-to 
        { token-balance: u0 } 
        (map-get? voting-power 
          { 
            property-id: property-id, 
            voter: tx-sender 
          }
        )
      ))
    )
    ;; Ensure voting is still open
    (asserts! 
      (< (var-get current-block-height) (get voting-deadline proposal)) 
      err-unauthorized
    )
    
    ;; Record vote with voting power
    (if vote
      (map-set property-votes
        { 
          property-id: property-id, 
          proposal-id: proposal-id 
        }
        (merge proposal { 
          yes-votes: (+ (get yes-votes proposal) (get token-balance voter-power)) 
        })
      )
      (map-set property-votes
        { 
          property-id: property-id, 
          proposal-id: proposal-id 
        }
        (merge proposal { 
          no-votes: (+ (get no-votes proposal) (get token-balance voter-power)) 
        })
      )
    )
    
    (ok true)
  )
)

;; Enhanced rental income distribution
(define-public (distribute-rental-income
  (property-id uint)
  (total-income uint)
)
  (let 
    (
      (property (unwrap! 
        (map-get? properties { property-id: property-id }) 
        err-property-not-found
      ))
    )
    ;; Enhanced validation
    (asserts! (> total-income u0) err-zero-value)
    (asserts! 
      (is-eq tx-sender (get management-wallet property)) 
      err-unauthorized
    )
    
    ;; Safe income addition
    (match (check-add (get rental-income property) total-income)
      success (begin
        (map-set properties 
          { property-id: property-id }
          (merge property { rental-income: success })
        )
        (ok true)
      )
      error (err error)
    )
  )
)


