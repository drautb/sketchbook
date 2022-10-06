#lang racket

(require plot)

(define a 0.73)
(define b 0.48)

(define A (/ (+ a b) 2))
(define G (sqrt (* a b)))
(define H (* 2 (/ (* a b) (+ a b))))

(printf "a: ~a    b: ~a~n~n" a b)
(printf "A: ~a~n" A)
(printf "G: ~a~n" G)
(printf "H: ~a~n~n" H)

(define range (+ a b))

(plot (list
       (polar (λ (theta) 1))
       (axes 0 0
             #:x-ticks? #f #:x-labels? #f
             #:y-ticks? #f #:y-labels? #f))
      #:x-min -1
      #:x-max 1
      #:y-min 0
      #:y-max 1
      #:width 500
      #:height 250
      #:title "Pythagorean Means")