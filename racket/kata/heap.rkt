;; An interview question I heard recently involved designing a heap to
;; minimize wasted space. I thought it would be a good exercise.

#lang racket

(require rackunit)

(define INDEX-SIZE 20)
(define INDEX-SLOT-SIZE 2)

;; get-available-idx-slot : vector? -> number?
;; Given a heap, this function finds the next open slot in the heap index.
(define (get-available-idx-slot heap)
  (define (find-next-slot heap n)
    (cond [(> n (vector-length heap)) (error 'heap-idx-out-of-bounds)]
          [(eq? n INDEX-SIZE) (error 'heap-full)]
          [(eq? (vector-ref heap n) 0) n]
          [else (find-next-slot heap (+ n INDEX-SLOT-SIZE))]))
  (find-next-slot heap 0))

(let ([test-heap (make-vector 25)])
  (check-eq? (get-available-idx-slot test-heap) 0)

  (vector-set! test-heap 0 1)
  (check-eq? (get-available-idx-slot test-heap) 2)

  (vector-fill! test-heap 1)
  (vector-set! test-heap 18 0)
  (check-eq? (get-available-idx-slot test-heap) 18)

  (vector-fill! test-heap 1)
  (check-exn exn:fail? (λ () (get-available-idx-slot test-heap))))

;; find-contiguous-block : vector? -> number? -> number?
;; Given a heap, and a size, returns the first address in an available block of that size.
(define (find-contiguous-block heap size)
  20)

(let ([test-heap (make-vector 20)])
  (check-eq? (find-contiguous-block test-heap 1) 20)

  (vector-set! test-heap 2 20)
  (vector-set! test-heap 3 10)
  (check-eq? (find-contiguous-block test-heap 1) 30))

;; new : vector? -> number? -> number?
;; Returns the index of a memory segment in heap of length size.
;; Throws an error if there isn't enough memory.
(define (new heap size)
  (define idx-slot (get-available-idx-slot heap))
  (define block-start (find-contiguous-block heap size))
  block-start)

; (let ([test-heap (make-vector 100)])
;   ;; The first INDEX-SIZE spots should be used for the idx
;   (check-eq? (new test-heap 1) INDEX-SIZE)
;   (check-eq? (new test-heap 1) (+ 1 INDEX-SIZE))
;   (check-eq? (new test-heap 1) (+ 2 INDEX-SIZE))
;   (check-eq? (new test-heap 1) (+ 3 INDEX-SIZE))
;   )
