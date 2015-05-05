#lang racket

(define (sub-one! n)
  (set! n (- n 1))
  n)

(define (sub-one n)
  (- n 1))

(define ITERATIONS 50000000)

(define (benchmark fn iterations)
  (time 
   (let loop ([n iterations])
     (if (zero? n)
         'done
         (loop (fn n))))))

(benchmark sub-one! ITERATIONS)
(benchmark sub-one ITERATIONS)

(struct point (x) #:mutable)

(define (move-right! p)
  (set-point-x! (add1 (point-x p))))

(define (move-right p)
  (point (add1 (point-x p))))

(define (benchmark-struct fn iterations obj)
  (time
   (let loop ([n iterations])
     (if (zero? n)
         'done
         (begin (fn obj)
                

