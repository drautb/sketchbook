#lang racket/base

(require racket/list
         "interval-mapping.rkt")

;; This module is for the main game logic.

;; set? -> number -> number -> number -> boolean
;; Do the three given card indices constitute a set?
(define (set? c1 c2 c3)
  ;; Four attributes must each be the same or unique for all three cards:
  ;; - Color
  ;; - Shape
  ;; - Shading
  ;; - Count
  (define component-lists (map card->components (list c1 c2 c3)))
  (define triplets (transpose component-lists))
  (for/and ([t triplets]) (unique-or-same t)))

(define (transpose xss)
  (apply map list xss))

(define (unique-or-same ns)
  (or (apply = ns)
      (= (length ns) (length (remove-duplicates ns)))))

(module+ rackunit
  (require rackunit)

  (check-true (set? 0 1 2))
  (check-true (set? 3 4 5))
  (check-true (set? 0 10 20))
  (check-true (set? 10 33 77))

  (check-false (set? 0 1 3))
  (check-false (set? 0 2 3)))
