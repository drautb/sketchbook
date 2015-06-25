#lang racket

(define NUMERALS
  (make-hash (list (cons 1 "I")
                   (cons 4 "IV")
                   (cons 5 "V")
                   (cons 9 "IX")
                   (cons 10 "X")
                   (cons 40 "XL")
                   (cons 50 "L")
                   (cons 90 "XC")
                   (cons 100 "C")
                   (cons 400 "CD")
                   (cons 500 "D")
                   (cons 900 "CM")
                   (cons 1000 "M"))))

(define DIVISORS (sort (hash-keys NUMERALS) >))

(define (build-string n str)
  (string-append* (make-list n str)))

(define (reduce n divisor)
  (define-values (times remainder) (quotient/remainder n divisor))
  (values (build-string times (hash-ref NUMERALS divisor)) remainder))

(define (convert n)
  (define (expand n d)
    (define-values (str remainder) (reduce n d))
    (if (= 0 remainder)
        str
        (string-append str (expand remainder (second (member d DIVISORS))))))
  (expand n (first DIVISORS)))


;; TESTS
(module+
  test
  (require rackunit)

  (define (check-reduce number divisor expected-string expected-remainder)
    (define-values (str remainder) (reduce number divisor))
    (check-equal? str expected-string)
    (check-equal? remainder expected-remainder))

  (check-reduce 0 5 "" 0)
  (check-reduce 4 4 "IV" 0)
  (check-reduce 5 5 "V" 0)
  (check-reduce 10 10 "X" 0)
  (check-reduce 11 10 "X" 1)
  (check-reduce 21 10 "XX" 1)
  (check-reduce 50 50 "L" 0)
  (check-reduce 51 50 "L" 1)
  (check-reduce 90 90 "XC" 0)
  (check-reduce 151 50 "LLL" 1)
  (check-reduce 1000 500 "DD" 0)
  (check-reduce 1000 1000 "M" 0)

  (define (check-convert number expected)
    (check-equal? (convert number) expected))

  (check-convert 0 "")
  (check-convert 1 "I")
  (check-convert 10 "X")
  (check-convert 100 "C")
  (check-convert 1000 "M")
  (check-convert 1949 "MCMXLIX")
  (check-convert 2 "II")
  (check-convert 20 "XX")
  (check-convert 2013 "MMXIII")
  (check-convert 3999 "MMMCMXCIX")
  (check-convert 4 "IV")
  (check-convert 40 "XL")
  (check-convert 400 "CD")
  (check-convert 4999 "MMMMCMXCIX")
  (check-convert 5 "V")
  (check-convert 50 "L")
  (check-convert 500 "D")
  (check-convert 6 "VI")
  (check-convert 9 "IX")
  (check-convert 90 "XC")
  (check-convert 900 "CM")
  )
