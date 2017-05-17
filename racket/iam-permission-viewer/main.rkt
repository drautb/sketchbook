#lang racket/gui

(require json)

;; ---------------------------------------------------------------------
;; Service/Permission Data
;; Extracted from https://awsiamconsole.s3.amazonaws.com/iam/assets/js/bundles/policies.js
(define aws-data
  (with-input-from-file "/Users/drautb/GitHub/drautb/sketchbook/racket/iam-permission-viewer/data.json"
    (lambda () (read-json))))

(define service-data (hash-ref (hash-ref aws-data 'PolicyEditorConfig) 'serviceMap))
(define service-names (map symbol->string (hash-keys service-data)))

(define permission-names empty)

(define (reload-permissions service-name)
  (define service (hash-ref service-data (string->symbol service-name)))
  (define prefix (hash-ref service 'StringPrefix))
  (set! permission-names (map (λ (permission)
                                (string-append prefix ":" permission))
                              (hash-ref service 'Actions)))
  (send permission-list set permission-names))

;; ---------------------------------------------------------------------
;; GUI Stuff
(define fixed-width-font
  (send the-font-list find-or-create-font 12.0 'modern 'normal 'normal))


(define (filter-choices search-field list-box data)
  (let ([search-str (string-downcase (send search-field get-value))])
    (send list-box set (filter (λ (name)
                                 (string-contains? (string-downcase name) search-str))
                               data))))

(define frame (new frame%
                   [label "IAM Permission Browser"]
                   [min-width 800]
                   [min-height 800]))
(define main-panel (new horizontal-panel%
                        [parent frame]
                        [alignment '(center center)]))

(define left-panel (new vertical-panel%
                        [parent main-panel]
                        [alignment '(center center)]))
(define service-search (new text-field%
                            [parent left-panel]
                            [label "Service Search:"]
                            [callback (λ (text-field event)
                                        (filter-choices text-field service-list service-names))]))

(define service-list (new list-box%
                          [parent left-panel]
                          [label ""]
                          [choices service-names]
                          [callback (λ (list-box event)
                                      (let ([selected-service (send list-box get-string-selection)])
                                        (reload-permissions selected-service)))]))

(define right-panel (new vertical-panel%
                         [parent main-panel]
                         (alignment '(center center))))
(define permission-search (new text-field%
                               [parent right-panel]
                               [label "Permission Search:"]
                               [callback (λ (text-field event)
                                           (filter-choices text-field permission-list permission-names))]))
(define permission-list (new list-box%
                             [parent right-panel]
                             [label ""]
                             [font fixed-width-font]
                             [choices permission-names]))

(send frame show #t)
