;; Crypto Mining Rewards Platform
;; A blockchain-based mining rewards system with progressive challenges and incentives

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-CHALLENGE (err u3))
(define-constant ERR-ALREADY-COMPLETED (err u4))
(define-constant ERR-WRONG-SOLUTION (err u5))
(define-constant ERR-TIME-LOCKED (err u6))
(define-constant ERR-INSUFFICIENT-STAKE (err u7))
(define-constant ERR-INVALID-INPUT (err u8))

;; Data Variables
(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var current-challenge uint u0)
(define-data-var mining-entry-stake uint u1000000) ;; 1 STX
(define-data-var total-reward-pool uint u0)
(define-data-var max-mining-reward uint u1000000000) ;; Reasonable max reward

;; Mining Challenge Structure
(define-map mining-challenges
    uint
    {
        difficulty-clue: (string-utf8 256),
        hash-target: (buff 32), ;; SHA256 hash of the mining solution
        unlock-block-height: uint,
        mining-reward: uint,
        challenge-completed: bool
    }
)

;; Miner Progress Tracking
(define-map miner-progress
    principal
    {
        current-challenge-level: uint,
        completed-challenges: (list 20 uint),
        last-mining-attempt: uint,
        total-challenges-solved: uint
    }
)

;; Miner Solutions History
(define-map challenge-solutions
    {challenge: uint, miner: principal}
    {
        attempt-count: uint,
        solved-block: (optional uint)
    }
)

;; Top Miners
(define-map challenge-top-miners
    uint
    (list 10 {miner: principal, solved-at-block: uint})
)

;; Input Validation Functions
(define-private (is-platform-admin)
    (is-eq tx-sender (var-get platform-admin)))

(define-private (is-valid-challenge-id (challenge-id uint))
    (and (> challenge-id u0) (<= challenge-id u100)))

(define-private (is-valid-difficulty-description (description (string-utf8 256)))
    (and 
        (> (len description) u0) 
        (<= (len description) u256)))

(define-private (is-valid-hash-target (hash (buff 32)))
    (and 
        (is-eq (len hash) u32)
        (not (is-eq hash 0x00))))

(define-private (is-valid-block-height (height uint))
    (> height block-height))

(define-private (is-valid-mining-reward (reward uint))
    (and 
        (> reward u0) 
        (<= reward (var-get max-mining-reward))))

;; Platform Management Functions
(define-public (initialize-mining-platform)
    (begin
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (var-set platform-active true)
        (var-set current-challenge u0)
        (var-set total-reward-pool u0)
        (ok true)))

(define-public (add-mining-challenge
    (challenge-id uint)
    (difficulty-description (string-utf8 256))
    (hash-target (buff 32))
    (unlock-block-height uint)
    (mining-reward uint))
    (begin
        ;; Input validation checks
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-challenge-id challenge-id) ERR-INVALID-INPUT)
        (asserts! (is-valid-difficulty-description difficulty-description) ERR-INVALID-INPUT)
        (asserts! (is-valid-hash-target hash-target) ERR-INVALID-INPUT)
        (asserts! (is-valid-block-height unlock-block-height) ERR-INVALID-INPUT)
        (asserts! (is-valid-mining-reward mining-reward) ERR-INVALID-INPUT)
        
        ;; Existing logic with validated inputs
        (map-set mining-challenges challenge-id
            {
                difficulty-clue: difficulty-description,
                hash-target: hash-target,
                unlock-block-height: unlock-block-height,
                mining-reward: mining-reward,
                challenge-completed: false
            })
        
        ;; Safe addition with overflow check
        (let ((new-total (+ (var-get total-reward-pool) mining-reward)))
            (asserts! (>= new-total (var-get total-reward-pool)) ERR-INVALID-INPUT)
            (var-set total-reward-pool new-total))
        
        (ok true)))

;; Miner Registration
(define-public (register-miner)
    (begin
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        ;; Require entry stake
        (try! (stx-transfer? (var-get mining-entry-stake) tx-sender (var-get platform-admin)))
        
        (map-set miner-progress tx-sender
            {
                current-challenge-level: u0,
                completed-challenges: (list),
                last-mining-attempt: u0,
                total-challenges-solved: u0
            })
        (ok true)))

;; Mining Challenge Submission
(define-public (submit-mining-solution
    (challenge-id uint)
    (mining-solution (buff 32)))
    (let (
        (challenge (unwrap! (map-get? mining-challenges challenge-id) ERR-INVALID-CHALLENGE))
        (miner (unwrap! (map-get? miner-progress tx-sender) ERR-INVALID-CHALLENGE))
        )
        ;; Check platform availability
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        (asserts! (>= block-height (get unlock-block-height challenge)) ERR-TIME-LOCKED)
        (asserts! (not (get challenge-completed challenge)) ERR-ALREADY-COMPLETED)
        
        ;; Verify mining solution - directly compare the hashes
        (if (is-eq mining-solution (get hash-target challenge))
            (begin
                ;; Update challenge status
                (map-set mining-challenges challenge-id
                    (merge challenge {challenge-completed: true}))
                
                ;; Update miner progress
                (map-set miner-progress tx-sender
                    (merge miner {
                        current-challenge-level: (+ challenge-id u1),
                        completed-challenges: (unwrap! (as-max-len? 
                            (append (get completed-challenges miner) challenge-id) u20)
                            ERR-INVALID-CHALLENGE),
                        total-challenges-solved: (+ (get total-challenges-solved miner) u1)
                    }))
                
                ;; Record solution
                (map-set challenge-solutions
                    {challenge: challenge-id, miner: tx-sender}
                    {
                        attempt-count: u1,
                        solved-block: (some block-height)
                    })
                
                ;; Award mining reward
                (try! (stx-transfer? (get mining-reward challenge) (var-get platform-admin) tx-sender))
                
                ;; Record top miners
                (match (map-get? challenge-top-miners challenge-id)
                    top-miners (map-set challenge-top-miners challenge-id
                        (unwrap! (as-max-len?
                            (append top-miners {miner: tx-sender, solved-at-block: block-height})
                            u10)
                            ERR-INVALID-CHALLENGE))
                    (map-set challenge-top-miners challenge-id
                        (list {miner: tx-sender, solved-at-block: block-height})))
                
                (ok true))
            ERR-WRONG-SOLUTION)))

;; Read-only functions
(define-read-only (get-current-mining-difficulty (challenge-id uint))
    (match (map-get? mining-challenges challenge-id)
        challenge (if (>= block-height (get unlock-block-height challenge))
            (ok (get difficulty-clue challenge))
            ERR-TIME-LOCKED)
        ERR-INVALID-CHALLENGE))

(define-read-only (get-miner-status (miner principal))
    (map-get? miner-progress miner))

(define-read-only (get-challenge-top-miners (challenge-id uint))
    (map-get? challenge-top-miners challenge-id))

(define-read-only (get-platform-stats)
    {
        active: (var-get platform-active),
        current-challenge: (var-get current-challenge),
        total-reward-pool: (var-get total-reward-pool),
        mining-entry-stake: (var-get mining-entry-stake)
    })