;; title: step-goal-negotiation-engine
;; version: 1.0.0
;; summary: Automatically lowers daily targets based on your couch-sitting patterns
;; description: Dynamic step goal adjustment system that adapts to user behavior patterns

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-goal (err u101))
(define-constant err-invalid-steps (err u102))
(define-constant err-no-goal-set (err u103))
(define-constant err-already-recorded (err u104))
(define-constant err-not-found (err u105))

(define-constant default-goal u10000)
(define-constant min-goal u1000)
(define-constant max-goal u30000)
(define-constant adjustment-threshold u7) ;; days before adjustment
(define-constant reduction-rate u90) ;; 90% of previous goal
(define-constant increase-rate u105) ;; 105% of previous goal

;; data vars
(define-data-var current-goal uint default-goal)
(define-data-var total-users uint u0)
(define-data-var total-days-tracked uint u0)

;; data maps
(define-map user-goals principal uint)
(define-map user-stats 
  principal 
  {
    total-days: uint,
    successful-days: uint,
    current-streak: uint,
    longest-streak: uint,
    last-recorded-day: uint
  }
)

(define-map daily-records
  { user: principal, day: uint }
  {
    steps: uint,
    goal: uint,
    achieved: bool,
    timestamp: uint
  }
)

(define-map weekly-performance
  { user: principal, week: uint }
  {
    total-steps: uint,
    days-completed: uint,
    average-completion-rate: uint
  }
)

;; private functions
(define-private (calculate-new-goal (current uint) (success-rate uint))
  (let
    (
      (adjusted-goal 
        (if (>= success-rate u70)
          ;; If success rate >= 70%, increase goal slightly
          (/ (* current increase-rate) u100)
          ;; Otherwise, reduce goal
          (/ (* current reduction-rate) u100)
        )
      )
    )
    (if (< adjusted-goal min-goal)
      min-goal
      (if (> adjusted-goal max-goal)
        max-goal
        adjusted-goal
      )
    )
  )
)

(define-private (calculate-success-rate (successful uint) (total uint))
  (if (is-eq total u0)
    u0
    (/ (* successful u100) total)
  )
)

(define-private (get-current-day)
  (/ stacks-block-height u144) ;; Approximate days (144 blocks per day)
)

;; public functions
(define-public (set-initial-goal (goal uint))
  (begin
    (asserts! (and (>= goal min-goal) (<= goal max-goal)) err-invalid-goal)
    (ok (map-set user-goals tx-sender goal))
  )
)

(define-public (record-daily-steps (steps uint))
  (let
    (
      (current-day (get-current-day))
      (user-goal (default-to default-goal (map-get? user-goals tx-sender)))
      (achieved (>= steps user-goal))
      (existing-stats (default-to 
        { total-days: u0, successful-days: u0, current-streak: u0, longest-streak: u0, last-recorded-day: u0 }
        (map-get? user-stats tx-sender)
      ))
      (is-consecutive (is-eq (+ (get last-recorded-day existing-stats) u1) current-day))
      (new-streak (if (and achieved is-consecutive)
        (+ (get current-streak existing-stats) u1)
        (if achieved u1 u0)
      ))
    )
    (asserts! (> steps u0) err-invalid-steps)
    (asserts! (is-none (map-get? daily-records { user: tx-sender, day: current-day })) err-already-recorded)
    
    ;; Record daily activity
    (map-set daily-records
      { user: tx-sender, day: current-day }
      {
        steps: steps,
        goal: user-goal,
        achieved: achieved,
        timestamp: stacks-block-height
      }
    )
    
    ;; Update user stats
    (map-set user-stats tx-sender
      {
        total-days: (+ (get total-days existing-stats) u1),
        successful-days: (if achieved (+ (get successful-days existing-stats) u1) (get successful-days existing-stats)),
        current-streak: new-streak,
        longest-streak: (if (> new-streak (get longest-streak existing-stats)) new-streak (get longest-streak existing-stats)),
        last-recorded-day: current-day
      }
    )
    
    ;; Auto-adjust goal if threshold reached
    (if (is-eq (mod (get total-days existing-stats) adjustment-threshold) u0)
      (auto-adjust-goal tx-sender)
      (ok true)
    )
  )
)

(define-public (auto-adjust-goal (user principal))
  (let
    (
      (stats (unwrap! (map-get? user-stats user) err-not-found))
      (success-rate (calculate-success-rate (get successful-days stats) (get total-days stats)))
      (current-user-goal (default-to default-goal (map-get? user-goals user)))
      (new-goal (calculate-new-goal current-user-goal success-rate))
    )
    (ok (map-set user-goals user new-goal))
  )
)

(define-public (manually-adjust-goal (new-goal uint))
  (begin
    (asserts! (and (>= new-goal min-goal) (<= new-goal max-goal)) err-invalid-goal)
    (ok (map-set user-goals tx-sender new-goal))
  )
)

(define-public (reset-streak)
  (let
    (
      (stats (unwrap! (map-get? user-stats tx-sender) err-not-found))
    )
    (ok (map-set user-stats tx-sender (merge stats { current-streak: u0 })))
  )
)

;; read only functions
(define-read-only (get-user-goal (user principal))
  (ok (default-to default-goal (map-get? user-goals user)))
)

(define-read-only (get-user-stats (user principal))
  (ok (map-get? user-stats user))
)

(define-read-only (get-daily-record (user principal) (day uint))
  (ok (map-get? daily-records { user: user, day: day }))
)

(define-read-only (get-current-streak (user principal))
  (ok (get current-streak (default-to 
    { total-days: u0, successful-days: u0, current-streak: u0, longest-streak: u0, last-recorded-day: u0 }
    (map-get? user-stats user)
  )))
)

(define-read-only (get-success-rate (user principal))
  (let
    (
      (stats (map-get? user-stats user))
    )
    (match stats
      user-stats-data (ok (calculate-success-rate (get successful-days user-stats-data) (get total-days user-stats-data)))
      (ok u0)
    )
  )
)

(define-read-only (get-total-steps (user principal) (start-day uint) (end-day uint))
  (ok u0) ;; Placeholder for range query implementation
)

(define-read-only (get-default-goal)
  (ok default-goal)
)

