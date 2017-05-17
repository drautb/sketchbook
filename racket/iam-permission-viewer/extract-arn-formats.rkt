#lang racket

(require json)

(define aws-data
  (with-input-from-file "/Users/drautb/GitHub/drautb/sketchbook/racket/iam-permission-viewer/data.json"
    (lambda () (read-json))))

(define service-data (hash-ref (hash-ref aws-data 'PolicyEditorConfig) 'serviceMap))

(define arns
  (for/hash ([s (hash-map service-data
                          (λ (service-name data)
                            (define service-prefix
                              (string->symbol (hash-ref data 'StringPrefix)))
                            (define arn-format
                              (if (hash-has-key? data 'ARNFormat)
                                  (hash-ref data 'ARNFormat)
                                  "*"))
                            (list service-prefix arn-format)))])
    (values (first s) (second s))))

(call-with-output-file "arn-formats.json"
  (λ (op) (write-json arns op)))
