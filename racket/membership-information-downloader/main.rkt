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

(define username-field (new text-field%
                            [label "Username"]
                            [parent left-panel]))

(define password-field (new text-field%
                            [label "Password"]
                            [parent left-panel]
                            [style '(single password)]))

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

(define progress (new gauge%
                      [label #f]
                      [parent left-panel]
                      [range 100]))


(define (download-directory)
  (log-info "Downloading directory...")
  (send frame enable #f)
  (define login-cookie (login (send username-field get-value)
                              (send password-field get-value)))
  (log-info (format "Received login cookie: ~a" login-cookie))
  (define unit-id (get-unit-id login-cookie))
  (log-info (format "Received unit id: ~a" unit-id))
  (define household-ids (get-household-ids login-cookie unit-id))
  (log-info (format "Received ~a household ids" (length household-ids)))
  (send progress set-range (length household-ids))
  (define household-infos
    (map (lambda (id)
           (send progress set-value (+ 1 (send progress get-value)))
           (define info (get-household-info login-cookie id))
           ; (log-info (format "~a" info))
           info)
         household-ids))
  (define csv-str (build-csv household-infos))
  (send info-table set-value csv-str)
  ; (send wait-dialog show #f)
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