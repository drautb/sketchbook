#lang racket/base

(require racket/gui
         "request.rkt"
         "church-account.rkt"
         "csv.rkt")


;; GUI Components
(define frame (new frame% [label "Membership Information"]))

(define main-panel (new horizontal-panel% [parent frame]))

(define left-panel (new group-box-panel%
                        [parent main-panel]
                        [label "Login Information"]))

(define da-token-field (new text-field%
                            [label "Token"]
                            [parent left-panel]))

(define unit-id-field (new text-field%
                           [label "Unit ID"]
                           [parent left-panel]))

(define download-bt (new button%
                         [parent left-panel]
                         [label "Download Directory"]
                         [callback (lambda (button event) (download-directory))]))

(define right-panel (new group-box-panel%
                         [parent main-panel]
                         [label "Membership Information"]))

(define info-table (new text-field%
                        [label #f]
                        [parent right-panel]
                        [min-width 800]
                        [min-height 600]
                        [style '(multiple hscroll)]))

(define save-csv-btn (new button%
                          [parent right-panel]
                          [label "Save CSV"]
                          [callback (lambda (button event)
                                      (save-csv (send info-table get-value)))]))


(define (download-directory)
  (send frame enable #f)
  (define household-info (get-household-info (send da-token-field get-value)
                                             (send unit-id-field get-value)))
  (define csv-str (build-csv household-info))
  (send info-table set-value csv-str)
  (send frame enable #t))


(define (save-csv data)
  (define path
    (put-file "Save Addresses to CSV"
              frame
              #f
              "addresses"
              "csv"))
  (when path (call-with-output-file path
               (lambda (out)
                 (display data out))
               #:exists 'truncate)))

(define (log-info msg)
  (log-message (current-logger) 'info #f msg #f))

(send frame show #t)