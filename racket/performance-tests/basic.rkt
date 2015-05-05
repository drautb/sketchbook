#lang racket

(define ITERATIONS 50000000)
(printf "~nPerforming Benchmarks with ~a iterations ***~n~n" ITERATIONS)


;; Is it faster to use set! in a sub-one function? Or not?
;;
;; sub-one is about 30% faster than sub-one!
(define (benchmark fn iterations)
  (time
    (let loop ([n iterations])
      (unless (zero? n)
        (loop (fn n))))))

(define (sub-one! n)
  (set! n (- n 1))
  n)

(define (sub-one n)
  (- n 1))

(displayln "Benchmarking sub-one!")
(benchmark sub-one! ITERATIONS)
(displayln "Benchmarking sub-one")
(benchmark sub-one ITERATIONS)


;; Is it faster to create a new struct?
;; Or mutate a #:mutable struct?
;;
;; Using the builtin mutation functions is faster, I assume simply because
;; we don't have to allocate a new struct every time.
;;
;; Using move! is about 25% faster than move.
(struct point (x) #:mutable)

(define (move! p)
  (set-point-x! p (add1 (point-x p))))

(define (move p)
  (point (add1 (point-x p))))

(define my-point (point 1))

(displayln "Benchmarking move!")
(time
  (for ([n (in-range ITERATIONS)])
    (move! my-point)))

(displayln "Benchmarking move")
(time
  (for ([n (in-range ITERATIONS)])
    (move my-point)))


;; The racket guide talks about this, and I wanted to experiment with it.
;; Both of these examples perform similarly, which the guide supports,
;; since they're in a module definition here.
;;
;; If you run the second example, with defines, in the REPL, it is about
;; 65% slower than these samples.
(displayln "Benchmarking mutually recursive looping")
(time
  (letrec ([odd (lambda (x)
                  (if (zero? x)
                      #f
                      (even (sub1 x))))]
           [even (lambda (x)
                   (if (zero? x)
                       #t
                       (odd (sub1 x))))])
    (odd ITERATIONS)))

(displayln "Benchmarking mutually recursive looping without letrec")
(define (odd x)
  (if (zero? x)
      #f
      (even (sub1 x))))

(define (even x)
  (if (zero? x)
      #t
      (odd (sub1 x))))

(time (odd ITERATIONS))


