#!/usr/bin/env racket

#lang racket

;; I'm playing around with the racekt plot library, and
;; trying to figure out exactly why my power bills have
;; spiked recently. This is my sandbox.
;;
;; Cmd-line args to add:
;; -p       -> Parameters to plot
;; -min-x   ->
;; -max-x
;; -min-y
;; -max-y
;; -e       -> Show events on the plots

(require json
         plot
         racket/date)

;; prefix this lib so that it doesn't conflict with racket/date
(require (prefix-in srfi. srfi/19))

(define verbose-mode (make-parameter #f))
(define parameter-to-plot (make-parameter 'total-amount))
(define min-y (make-parameter 0))
(define max-y (make-parameter 100))
(define grid-lines (make-parameter #f))
(define show-events (make-parameter #f))

;; todo: Macro that only prints things if --verbose is on.
(define (log form . values)
  (cond [(verbose-mode)
         (apply fprintf (current-output-port) (string-append form "~n") values)]))

(define data (read-json (open-input-file "data.json")))
(define EVENTS (hash-ref data 'events))
(define BILLS (hash-ref data 'bills))

;; Always create new windows for plots
(plot-new-window? #t)

;; Use dates on the x-axis
(plot-x-ticks no-ticks)

;; date-to-tick : date? -> tick?
;; Given a date, converts it to a tick.
(define (date-to-tick date)
  (tick (date->seconds date) #t (srfi.date->string date "~b ~d '~y")))

;; date-hash-to-date : Hash -> date?
;; Given a date hash from the bill, this function will create a date object.
(define (date-hash-to-date date-hash)
  (date 0 0 0
        (hash-ref date-hash 'day)
        (hash-ref date-hash 'month)
        (hash-ref date-hash 'year)
        0 0 0 0))

;; end-date : Hash -> date?
;; Given a bill hash, this function returns a date object for the bill's end date.
(define (end-date bill)
  (date-hash-to-date (hash-ref bill 'endDate)))

;; total-amount : Hash -> Number
;; Given a bill's hash, this function extracts the total amount.
(define (total-amount bill)
  (hash-ref bill 'totalAmount))

;; usage : Hash -> Number
;; Given a bill's hash, this function extracts the total usage.
(define (usage bill)
  (hash-ref bill 'usage))

;; customer-service : Hash -> Number
;; Extracts the customer service fee for a bill.
(define (customer-service bill)
  (hash-ref bill 'customerService))

;; telecom-debt : Hash -> Number
;; Extracts the telecom debt fee for a bill.
(define (telecom-debt bill)
  (hash-ref bill 'telecomDebt))

;; municipal-use : Hash -> Number
;; Extracts the municipal use fee for a bill.
(define (municipal-use bill)
  (hash-ref bill 'municipalUse))

;; state-sales-tax : Hash -> Number
;; Extracts the state sales tax for a bill.
(define (state-sales-tax bill)
  (hash-ref bill 'stateSalesTax))

;; residential-transportation-fee : Hash -> Number
;; Extracts the residential transportation fee for a bill.
(define (residential-transportation-fee bill)
  (if (hash-has-key? bill 'residentialTransportationFee)
      (hash-ref bill 'residentialTransportationFee)
      0))

(define (non-usage bill)
   (+ (customer-service bill)
      (telecom-debt bill)
      (residential-transportation-fee bill)))

;; generate-line-data : Hash, Function -> Sequence of x,y
;; Given a hash of bills, and a function that calculates the y-value from a bill,
;; this function will generate the sequence data for a plot.
(define (generate-line-data bills y-fn)
  (for/list ([b bills])
    (let ([x (date->seconds (end-date b))]
          [y (apply y-fn (list b))])
      (list x y))))

(define (generate-histogram-data bills y-fn)
  (for/list ([b bills])
    (let ([x (srfi.date->string (end-date b) "~b '~y")]
          [y (apply y-fn (list b))])
      (list x y))))

(define (event-date event)
  (date-hash-to-date (hash-ref event 'date)))

(define (event->point-label event n)
  (point-label (list (date->seconds (event-date event))
                     (+ (/ (- (max-y) (min-y)) 2)
                        (* 20 (if (even? n) -1 1))))
               (string-append (hash-ref event 'description) " - " (date->string (event-date event) "~b ~d '~y"))))

(define (generate-event-points)
  (for/list ([e EVENTS]
             [n (length EVENTS)])
    (event->point-label e n)))

(provide date-hash-to-date
         end-date
         total-amount
         usage
         customer-service
         telecom-debt
         municipal-use
         state-sales-tax
         residential-transportation-fee
         generate-line-data)

(define-namespace-anchor anc)
(define ns (namespace-anchor->namespace anc))

(define settings
  (command-line
   #:program "Power Bill Analyzer"
   #:once-each
   [("-v" "--verbose") "Execute with verbose messages"
                       (verbose-mode #t)]
   [("-p" "--parameter") parameter "Specify the parameter to plot" (parameter-to-plot (string->symbol parameter))]
   [("--min-y") y "Lower bound of y-axis" (min-y (string->number y))]
   [("--max-y") y "Upper bound of y-axis" (max-y (string->number y))]
   [("-l" "--lines") "Display grid lines" (grid-lines #t)]
   [("-e" "--events") "Display events" (show-events #t)]))

(define (generate-renderers)
  (let ([renderers
         ; (list (discrete-histogram (generate-histogram-data BILLS (eval (parameter-to-plot) ns))))])
         (list (lines (generate-line-data BILLS (eval (parameter-to-plot) ns)))
               (x-ticks (for/list ([b BILLS])
                          (date-to-tick (end-date b)))))])
    (cond [(grid-lines) (set! renderers (append (tick-grid) renderers))])
    (cond [(show-events) (set! renderers (append (generate-event-points) renderers))])
    renderers))

(plot (generate-renderers)
      #:y-min (min-y)
      #:y-max (max-y)
      #:x-label "Time"
      #:y-label (symbol->string (parameter-to-plot)))
