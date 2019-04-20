#lang racket/base

(require racket/string)

(provide build-csv)


(define HEADER "\"Name\" \"Line 1\" \"Line 2\"")


(define (build-csv household-info)
  (define lines
    (map build-line (remove eof household-info)))
  (string-join (append (list HEADER) lines) "\n"))


(define (build-line info)
  (define address (hash-ref info 'address (make-hash)))
  (string-join
    (list (escape-result (hash-ref info 'name ""))
          (escape-result (hash-ref address 'line1 ""))
          (escape-result (hash-ref address 'line2 "")))))


(define (escape-result str)
  (format "\"~a\"" str))
