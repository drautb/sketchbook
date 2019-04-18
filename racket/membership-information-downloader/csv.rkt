#lang racket/base

(require racket/string)

(provide build-csv)


(define HEADER "\"Couple Name\" \"Address 1\" \"Address 2\" \"City\" \"State\" \"Postal\" \"Country\"")


(define (build-csv household-infos)
  (define lines
    (map build-line (remove eof household-infos)))
  (string-join (append (list HEADER) lines) "\n"))


(define (build-line info)
  (define address (hash-ref (hash-ref info 'householdInfo) 'address))
  (when (eq? address 'null) (set! address (make-hash)))
  (string-join
    (list (escape-result (hash-ref info 'coupleName ""))
          (escape-result (hash-ref address 'addr1 ""))
          (escape-result (hash-ref address 'addr2 ""))
          (escape-result (hash-ref address 'city ""))
          (escape-result (hash-ref address 'state ""))
          (escape-result (hash-ref address 'postal ""))
          (escape-result (hash-ref address 'countryIsoAlphaCode "")))))

(define (escape-result str)
  (format "\"~a\"" str))