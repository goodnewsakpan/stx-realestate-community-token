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
