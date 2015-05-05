#lang racket

(define SIDES-ON-DIE 6)
(define DIE-COUNT 2)

(define (gen-list n)
  (cond [(= n 0) empty]
        [else (cons n (gen-list (- n 1)))]))

(define SINGLE-DIE (reverse (gen-list SIDES-ON-DIE)))
(define counts (make-hash))
(define stats (make-hash))

(define (get-input)
  (filter (λ (n) (member n (hash-keys counts)))
          (read)))

(define (gen-counts)
  (for ([n1 SINGLE-DIE])
    (for ([n2 SINGLE-DIE])
      (let ([sum (+ n1 n2)])
        (cond [(hash-has-key? counts sum)
               (hash-set! counts sum (+ 1 (hash-ref counts sum)))]
              [else (hash-set! counts sum 1)])))))

(define (gen-stats)
  (for ([k (hash-keys counts)])
    (hash-set! stats 
               k 
               (exact->inexact (/ (hash-ref counts k)
                                  (expt SIDES-ON-DIE DIE-COUNT))))))

(gen-counts)
(gen-stats)

(define (calculate)
  (displayln "Enter the numbers you're interested in, surrounded by parentheses. For example: (3 7 9)")
  (let ([numbers-of-interest (get-input)]
        [likelihood 0.0])
    (for ([k numbers-of-interest])
      (set! likelihood (+ likelihood
                          (hash-ref stats k))))
    (fprintf (current-output-port) "The likelihood of rolling of of those numbers is ~a" likelihood)))

(calculate)
