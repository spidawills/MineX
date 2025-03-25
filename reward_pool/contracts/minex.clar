;; Crypto Mining Rewards Platform - Enhanced Version
;; Advanced implementation with miner tracking and comprehensive rewards

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-CHALLENGE (err u3))
(define-constant ERR-WRONG-SOLUTION (err u4))
(define-constant ERR-ALREADY-SOLVED (err u5))
(define-constant ERR-INSUFFICIENT-STAKE (err u6))

;; Platform State
(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var total-reward-pool uint u0)
(define-data-var mining-entry-fee uint u1000000) ;; 1 STX entry fee

;; Mining Challenge Structure
(define-map mining-challenges
    uint
    {
        difficulty-description: (string-utf8 256),
        solution-hash: (buff 32),
        reward-amount: uint,
        is-solved: bool,
        solver: (optional principal)
    }
)

;; Miner Progress Tracking
(define-map miner-progress
    principal
    {
        total-challenges-completed: uint,
        total-rewards-earned: uint,
        challenge-history: (list 20 uint)
    }
)

;; Authorization Check
(define-private (is-platform-admin)
    (is-eq tx-sender (var-get platform-admin)))

;; Platform Initialization
(define-public (initialize-platform)
    (begin
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (var-set platform-active true)
        (var-set total-reward-pool u0)
        (ok true)))

;; Miner Registration
(define-public (register-miner)
    (begin
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        
        ;; Collect entry fee
        (try! (stx-transfer? (var-get mining-entry-fee) tx-sender (var-get platform-admin)))
        
        ;; Initialize miner progress
        (map-set miner-progress tx-sender {
            total-challenges-completed: u0,
            total-rewards-earned: u0,
            challenge-history: (list)
        })
        
        (ok true)))

;; Create Mining Challenge
(define-public (create-challenge
    (challenge-id uint)
    (difficulty (string-utf8 256))
    (solution-hash (buff 32))
    (reward uint))
    (begin
        (asserts! (is-platform-admin) ERR-NOT-AUTHORIZED)
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        
        (map-set mining-challenges challenge-id {
            difficulty-description: difficulty,
            solution-hash: solution-hash,
            reward-amount: reward,
            is-solved: false,
            solver: none
        })
        
        (var-set total-reward-pool (+ (var-get total-reward-pool) reward))
        (ok true)))

;; Submit Mining Solution
(define-public (submit-solution
    (challenge-id uint)
    (submitted-solution (buff 32)))
    (let (
        (challenge (unwrap! (map-get? mining-challenges challenge-id) ERR-INVALID-CHALLENGE))
        (miner-progress (unwrap! (map-get? miner-progress tx-sender) ERR-INSUFFICIENT-STAKE))
        )
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        (asserts! (not (get is-solved challenge)) ERR-ALREADY-SOLVED)
        
        (if (is-eq submitted-solution (get solution-hash challenge))
            (begin
                ;; Mark challenge as solved
                (map-set mining-challenges challenge-id 
                    (merge challenge {
                        is-solved: true, 
                        solver: (some tx-sender)
                    }))
                
                ;; Update miner progress
                (map-set miner-progress tx-sender 
                    (merge miner-progress {
                        total-challenges-completed: (+ (get total-challenges-completed miner-progress) u1),
                        total-rewards-earned: (+ (get total-rewards-earned miner-progress) (get reward-amount challenge)),
                        challenge-history: (unwrap! 
                            (as-max-len? (append (get challenge-history miner-progress) challenge-id) u20) 
                            ERR-INVALID-CHALLENGE)
                    }))
                
                ;; Transfer reward
                (try! (stx-transfer? (get reward-amount challenge) (var-get platform-admin) tx-sender))
                
                (ok true)
            )
            ERR-WRONG-SOLUTION)))

;; Read-only Functions
(define-read-only (get-challenge-details (challenge-id uint))
    (map-get? mining-challenges challenge-id))

(define-read-only (get-miner-progress (miner principal))
    (map-get? miner-progress miner))

(define-read-only (get-platform-status)
    {
        active: (var-get platform-active),
        total-reward-pool: (var-get total-reward-pool),
        mining-entry-fee: (var-get mining-entry-fee)
    })