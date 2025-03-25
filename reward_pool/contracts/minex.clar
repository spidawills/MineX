;; Crypto Mining Rewards Platform 
;; Initial basic implementation of a blockchain-based mining rewards system

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-PLATFORM-NOT-ACTIVE (err u2))
(define-constant ERR-INVALID-CHALLENGE (err u3))
(define-constant ERR-WRONG-SOLUTION (err u4))

;; Platform State
(define-data-var platform-admin principal tx-sender)
(define-data-var platform-active bool false)
(define-data-var total-reward-pool uint u0)

;; Mining Challenge Structure
(define-map mining-challenges
    uint
    {
        difficulty-description: (string-utf8 256),
        solution-hash: (buff 32),
        reward-amount: uint,
        is-solved: bool
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
            is-solved: false
        })
        
        (var-set total-reward-pool (+ (var-get total-reward-pool) reward))
        (ok true)))

;; Submit Mining Solution
(define-public (submit-solution
    (challenge-id uint)
    (submitted-solution (buff 32)))
    (let (
        (challenge (unwrap! (map-get? mining-challenges challenge-id) ERR-INVALID-CHALLENGE))
        )
        (asserts! (var-get platform-active) ERR-PLATFORM-NOT-ACTIVE)
        (asserts! (not (get is-solved challenge)) ERR-INVALID-CHALLENGE)
        
        (if (is-eq submitted-solution (get solution-hash challenge))
            (begin
                ;; Mark challenge as solved
                (map-set mining-challenges challenge-id 
                    (merge challenge {is-solved: true}))
                (ok true)
            )
            ERR-WRONG-SOLUTION)))

;; Read-only Functions
(define-read-only (get-challenge-details (challenge-id uint))
    (map-get? mining-challenges challenge-id))

(define-read-only (get-platform-status)
    {
        active: (var-get platform-active),
        total-reward-pool: (var-get total-reward-pool)
    })