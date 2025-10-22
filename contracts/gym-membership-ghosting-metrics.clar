;; title: gym-membership-ghosting-metrics
;; version: 1.0.0
;; summary: Calculates cost-per-visit while you pretend walking to the fridge counts as cardio
;; description: Track gym membership utilization and calculate true ROI metrics

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-invalid-cost (err u201))
(define-constant err-no-membership (err u202))
(define-constant err-membership-expired (err u203))
(define-constant err-already-checked-in (err u204))
(define-constant err-invalid-duration (err u205))
(define-constant err-not-found (err u206))

(define-constant blocks-per-day u144)
(define-constant blocks-per-month u4320) ;; Approximately 30 days
(define-constant min-membership-cost u10)
(define-constant max-membership-cost u1000000)

;; data vars
(define-data-var total-memberships uint u0)
(define-data-var total-check-ins uint u0)
(define-data-var platform-revenue uint u0)

;; data maps
(define-map memberships
  principal
  {
    monthly-cost: uint,
    start-block: uint,
    end-block: uint,
    is-active: bool,
    total-paid: uint,
    membership-type: (string-ascii 20)
  }
)

(define-map check-ins
  { user: principal, visit-id: uint }
  {
    block-height: uint,
    day: uint,
    duration-minutes: uint,
    activity-type: (string-ascii 30)
  }
)

(define-map user-visit-stats
  principal
  {
    total-visits: uint,
    last-visit-block: uint,
    longest-gap-days: uint,
    current-gap-days: uint,
    total-duration-minutes: uint
  }
)

(define-map monthly-stats
  { user: principal, month: uint }
  {
    visits: uint,
    cost-paid: uint,
    cost-per-visit: uint,
    abandonment-score: uint
  }
)

(define-map ghost-status
  principal
  {
    is-ghost: bool,
    ghost-since-block: uint,
    total-wasted: uint,
    guilt-level: uint
  }
)

;; private functions
(define-private (calculate-days-between (block1 uint) (block2 uint))
  (/ (if (> block2 block1) (- block2 block1) (- block1 block2)) blocks-per-day)
)

(define-private (get-current-day)
  (/ stacks-block-height blocks-per-day)
)

(define-private (get-current-month)
  (/ stacks-block-height blocks-per-month)
)

(define-private (is-membership-active (user principal))
  (match (map-get? memberships user)
    membership (and 
      (get is-active membership)
      (>= stacks-block-height (get start-block membership))
      (<= stacks-block-height (get end-block membership))
    )
    false
  )
)

(define-private (calculate-cost-per-visit (total-cost uint) (visits uint))
  (if (is-eq visits u0)
    total-cost ;; If no visits, cost per visit is the entire cost
    (/ total-cost visits)
  )
)

(define-private (calculate-abandonment-score (days-since-last-visit uint))
  (if (<= days-since-last-visit u3)
    u0 ;; Active user
    (if (<= days-since-last-visit u7)
      u25 ;; Starting to ghost
      (if (<= days-since-last-visit u14)
        u50 ;; Definitely ghosting
        (if (<= days-since-last-visit u30)
          u75 ;; Full ghost mode
          u100 ;; Complete abandonment
        )
      )
    )
  )
)

;; public functions
(define-public (register-membership (monthly-cost uint) (duration-months uint) (membership-type (string-ascii 20)))
  (let
    (
      (total-cost (* monthly-cost duration-months))
      (duration-blocks (* duration-months blocks-per-month))
      (end-block (+ stacks-block-height duration-blocks))
    )
    (asserts! (and (>= monthly-cost min-membership-cost) (<= monthly-cost max-membership-cost)) err-invalid-cost)
    (asserts! (and (> duration-months u0) (<= duration-months u24)) err-invalid-duration)
    
    (map-set memberships tx-sender
      {
        monthly-cost: monthly-cost,
        start-block: stacks-block-height,
        end-block: end-block,
        is-active: true,
        total-paid: total-cost,
        membership-type: membership-type
      }
    )
    
    (var-set total-memberships (+ (var-get total-memberships) u1))
    (var-set platform-revenue (+ (var-get platform-revenue) total-cost))
    
    (ok true)
  )
)

(define-public (check-in (duration-minutes uint) (activity (string-ascii 30)))
  (let
    (
      (current-day (get-current-day))
      (existing-stats (default-to
        { total-visits: u0, last-visit-block: u0, longest-gap-days: u0, current-gap-days: u0, total-duration-minutes: u0 }
        (map-get? user-visit-stats tx-sender)
      ))
      (days-since-last (if (is-eq (get last-visit-block existing-stats) u0)
        u0
        (calculate-days-between (get last-visit-block existing-stats) stacks-block-height)
      ))
      (new-visit-id (+ (get total-visits existing-stats) u1))
    )
    (asserts! (is-membership-active tx-sender) err-membership-expired)
    
    ;; Record check-in
    (map-set check-ins
      { user: tx-sender, visit-id: new-visit-id }
      {
        block-height: stacks-block-height,
        day: current-day,
        duration-minutes: duration-minutes,
        activity-type: activity
      }
    )
    
    ;; Update visit stats
    (map-set user-visit-stats tx-sender
      {
        total-visits: new-visit-id,
        last-visit-block: stacks-block-height,
        longest-gap-days: (if (> days-since-last (get longest-gap-days existing-stats))
          days-since-last
          (get longest-gap-days existing-stats)
        ),
        current-gap-days: u0,
        total-duration-minutes: (+ (get total-duration-minutes existing-stats) duration-minutes)
      }
    )
    
    ;; Update total check-ins
    (var-set total-check-ins (+ (var-get total-check-ins) u1))
    (ok new-visit-id)
  )
)

(define-public (cancel-membership)
  (let
    (
      (membership (unwrap! (map-get? memberships tx-sender) err-no-membership))
    )
    (ok (map-set memberships tx-sender (merge membership { is-active: false })))
  )
)

(define-public (renew-membership (additional-months uint))
  (let
    (
      (membership (unwrap! (map-get? memberships tx-sender) err-no-membership))
      (additional-cost (* (get monthly-cost membership) additional-months))
      (additional-blocks (* additional-months blocks-per-month))
    )
    (asserts! (and (> additional-months u0) (<= additional-months u24)) err-invalid-duration)
    
    (map-set memberships tx-sender
      (merge membership
        {
          end-block: (+ (get end-block membership) additional-blocks),
          total-paid: (+ (get total-paid membership) additional-cost),
          is-active: true
        }
      )
    )
    
    (var-set platform-revenue (+ (var-get platform-revenue) additional-cost))
    (ok true)
  )
)

(define-public (update-ghost-status-public (user principal))
  (let
    (
      (stats (map-get? user-visit-stats user))
      (membership (map-get? memberships user))
    )
    (match stats
      user-stats
        (let
          (
            (days-since (calculate-days-between (get last-visit-block user-stats) stacks-block-height))
            (is-ghost (> days-since u14))
            (abandonment (calculate-abandonment-score days-since))
          )
          (match membership
            member-data
              (let
                (
                  (wasted-amount (if is-ghost
                    (/ (* (get monthly-cost member-data) days-since) u30)
                    u0
                  ))
                )
                (ok (map-set ghost-status user
                  {
                    is-ghost: is-ghost,
                    ghost-since-block: (if is-ghost (get last-visit-block user-stats) u0),
                    total-wasted: wasted-amount,
                    guilt-level: abandonment
                  }
                ))
              )
            (ok false)
          )
        )
      (ok false)
    )
  )
)

;; read only functions
(define-read-only (get-membership (user principal))
  (ok (map-get? memberships user))
)

(define-read-only (get-visit-stats (user principal))
  (ok (map-get? user-visit-stats user))
)

(define-read-only (get-check-in-record (user principal) (visit-id uint))
  (ok (map-get? check-ins { user: user, visit-id: visit-id }))
)

(define-read-only (get-cost-per-visit (user principal))
  (match (map-get? memberships user)
    membership
      (match (map-get? user-visit-stats user)
        stats (ok (calculate-cost-per-visit (get total-paid membership) (get total-visits stats)))
        (ok (get total-paid membership))
      )
    err-no-membership
  )
)

(define-read-only (get-ghost-status (user principal))
  (ok (map-get? ghost-status user))
)

(define-read-only (is-user-ghost (user principal))
  (match (map-get? ghost-status user)
    status (ok (get is-ghost status))
    (ok false)
  )
)

(define-read-only (get-total-wasted (user principal))
  (match (map-get? ghost-status user)
    status (ok (get total-wasted status))
    (ok u0)
  )
)

(define-read-only (get-platform-stats)
  (ok {
    total-memberships: (var-get total-memberships),
    total-check-ins: (var-get total-check-ins),
    platform-revenue: (var-get platform-revenue)
  })
)

