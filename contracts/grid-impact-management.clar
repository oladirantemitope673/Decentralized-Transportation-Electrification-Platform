;; Grid Impact Management Contract
;; Balances EV charging demand with electrical grid capacity

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-NODE-EXISTS (err u401))
(define-constant ERR-NODE-NOT-FOUND (err u402))
(define-constant ERR-INVALID-CAPACITY (err u403))
(define-constant ERR-CAPACITY-EXCEEDED (err u404))
(define-constant ERR-INVALID-PRIORITY (err u405))

;; Priority Levels
(define-constant PRIORITY-LOW u1)
(define-constant PRIORITY-MEDIUM u2)
(define-constant PRIORITY-HIGH u3)
(define-constant PRIORITY-CRITICAL u4)

;; Data Variables
(define-data-var next-node-id uint u1)
(define-data-var total-grid-capacity uint u0)
(define-data-var total-grid-load uint u0)
(define-data-var emergency-mode bool false)

;; Data Maps
(define-map grid-nodes uint {
  node-name: (string-ascii 50),
  max-capacity: uint,
  current-load: uint,
  connected-stations: (list 20 uint),
  operator: principal,
  is-active: bool,
  last-update-block: uint
})

(define-map charging-schedules uint {
  station-id: uint,
  scheduled-start: uint,
  scheduled-end: uint,
  requested-power: uint,
  priority-level: uint,
  is-approved: bool,
  grid-node: uint
})

(define-map load-balancing-rules uint {
  max-concurrent-sessions: uint,
  load-threshold-warning: uint,
  load-threshold-critical: uint,
  auto-throttle-enabled: bool,
  demand-response-active: bool
})

(define-map demand-response-events uint {
  event-start: uint,
  event-end: uint,
  target-reduction: uint,
  participating-stations: (list 50 uint),
  incentive-rate: uint,
  actual-reduction: uint
})

;; Public Functions

;; Register grid node
(define-public (register-grid-node (node-name (string-ascii 50)) (max-capacity uint) (operator principal))
  (let ((node-id (var-get next-node-id)))
    (asserts! (> max-capacity u0) ERR-INVALID-CAPACITY)
    (asserts! (is-none (map-get? grid-nodes node-id)) ERR-NODE-EXISTS)

    (map-set grid-nodes node-id {
      node-name: node-name,
      max-capacity: max-capacity,
      current-load: u0,
      connected-stations: (list),
      operator: operator,
      is-active: true,
      last-update-block: block-height
    })

    (map-set load-balancing-rules node-id {
      max-concurrent-sessions: u10,
      load-threshold-warning: (/ (* max-capacity u75) u100),
      load-threshold-critical: (/ (* max-capacity u90) u100),
      auto-throttle-enabled: true,
      demand-response-active: false
    })

    (var-set total-grid-capacity (+ (var-get total-grid-capacity) max-capacity))
    (var-set next-node-id (+ node-id u1))
    (ok node-id)))

;; Connect charging station to grid node
(define-public (connect-station-to-node (node-id uint) (station-id uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get operator node)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)

    (let ((current-stations (get connected-stations node)))
      (map-set grid-nodes node-id (merge node {
        connected-stations: (unwrap! (as-max-len? (append current-stations station-id) u20) ERR-CAPACITY-EXCEEDED)
      }))
      (ok true))))

;; Update grid node load
(define-public (update-node-load (node-id uint) (new-load uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get operator node)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-load (get max-capacity node)) ERR-CAPACITY-EXCEEDED)

    (let ((old-load (get current-load node))
          (rules (unwrap! (map-get? load-balancing-rules node-id) ERR-NODE-NOT-FOUND)))

      (map-set grid-nodes node-id (merge node {
        current-load: new-load,
        last-update-block: block-height
      }))

      (var-set total-grid-load (+ (- (var-get total-grid-load) old-load) new-load))

      ;; Check if load thresholds are exceeded
      (if (>= new-load (get load-threshold-critical rules))
        (var-set emergency-mode true)
        (if (< new-load (get load-threshold-warning rules))
          (var-set emergency-mode false)
          true))

      (ok true))))

;; Schedule charging session
(define-public (schedule-charging (station-id uint) (start-time uint) (end-time uint) (power-requested uint) (priority uint) (node-id uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND))
        (schedule-id (+ (* node-id u1000) station-id)))

    (asserts! (<= priority PRIORITY-CRITICAL) ERR-INVALID-PRIORITY)
    (asserts! (> end-time start-time) ERR-INVALID-CAPACITY)
    (asserts! (> power-requested u0) ERR-INVALID-CAPACITY)

    (let ((available-capacity (- (get max-capacity node) (get current-load node)))
          (is-approved (and (>= available-capacity power-requested) (not (var-get emergency-mode)))))

      (map-set charging-schedules schedule-id {
        station-id: station-id,
        scheduled-start: start-time,
        scheduled-end: end-time,
        requested-power: power-requested,
        priority-level: priority,
        is-approved: is-approved,
        grid-node: node-id
      })

      (ok { schedule-id: schedule-id, approved: is-approved }))))

;; Initiate demand response event
(define-public (initiate-demand-response (node-id uint) (target-reduction uint) (duration-blocks uint) (incentive-rate uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND))
        (event-id (+ (* node-id u100) block-height)))

    (asserts! (or (is-eq tx-sender (get operator node)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (> target-reduction u0) ERR-INVALID-CAPACITY)

    (map-set demand-response-events event-id {
      event-start: block-height,
      event-end: (+ block-height duration-blocks),
      target-reduction: target-reduction,
      participating-stations: (get connected-stations node),
      incentive-rate: incentive-rate,
      actual-reduction: u0
    })

    (let ((rules (unwrap! (map-get? load-balancing-rules node-id) ERR-NODE-NOT-FOUND)))
      (map-set load-balancing-rules node-id (merge rules { demand-response-active: true })))

    (ok event-id)))

;; Complete demand response event
(define-public (complete-demand-response (event-id uint) (actual-reduction uint))
  (let ((event (unwrap! (map-get? demand-response-events event-id) ERR-NODE-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= block-height (get event-end event)) ERR-INVALID-CAPACITY)

    (map-set demand-response-events event-id (merge event { actual-reduction: actual-reduction }))
    (ok true)))

;; Update load balancing rules
(define-public (update-load-balancing-rules (node-id uint) (max-sessions uint) (warning-threshold uint) (critical-threshold uint) (auto-throttle bool))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND)))
    (asserts! (or (is-eq tx-sender (get operator node)) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (asserts! (< warning-threshold critical-threshold) ERR-INVALID-CAPACITY)
    (asserts! (<= critical-threshold (get max-capacity node)) ERR-INVALID-CAPACITY)

    (map-set load-balancing-rules node-id {
      max-concurrent-sessions: max-sessions,
      load-threshold-warning: warning-threshold,
      load-threshold-critical: critical-threshold,
      auto-throttle-enabled: auto-throttle,
      demand-response-active: (get demand-response-active (unwrap! (map-get? load-balancing-rules node-id) ERR-NODE-NOT-FOUND))
    })
    (ok true)))

;; Read-only Functions

(define-read-only (get-grid-node (node-id uint))
  (map-get? grid-nodes node-id))

(define-read-only (get-charging-schedule (schedule-id uint))
  (map-get? charging-schedules schedule-id))

(define-read-only (get-load-balancing-rules (node-id uint))
  (map-get? load-balancing-rules node-id))

(define-read-only (get-demand-response-event (event-id uint))
  (map-get? demand-response-events event-id))

(define-read-only (get-grid-status)
  {
    total-capacity: (var-get total-grid-capacity),
    total-load: (var-get total-grid-load),
    utilization-rate: (if (> (var-get total-grid-capacity) u0)
                        (/ (* (var-get total-grid-load) u100) (var-get total-grid-capacity))
                        u0),
    emergency-mode: (var-get emergency-mode),
    total-nodes: (- (var-get next-node-id) u1)
  })

(define-read-only (calculate-available-capacity (node-id uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND)))
    (ok (- (get max-capacity node) (get current-load node)))))

(define-read-only (get-node-utilization (node-id uint))
  (let ((node (unwrap! (map-get? grid-nodes node-id) ERR-NODE-NOT-FOUND)))
    (if (> (get max-capacity node) u0)
      (ok (/ (* (get current-load node) u100) (get max-capacity node)))
      ERR-INVALID-CAPACITY)))
