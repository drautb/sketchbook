#lang racket

(require racket/draw
         metapict)

(provide get-shape-pict)

(define (get-shape-pict color-idx shade-idx shape-idx)
  (vector-ref shapes (compute-idx color-idx shade-idx shape-idx)))

(define shapes (make-vector (* 3 3 3)))

(set-curve-pict-size 50 100)
(define shape-window (window 0 10 0 28))

(define color-list (list "red" "green" "blue"))
(define colors  (list->vector color-list))
(define hatches (list->vector (map (lambda (c)
                                     (new brush%
                                          [color c]
                                          [style 'horizontal-hatch]))
                                   color-list)))


;; DIAMONDS
(define pt0 (pt 5  1 ))
(define pt1 (pt 10 14))
(define pt2 (pt 5  27))
(define pt3 (pt 0  14))

(define diamond
  (curve-append (curve pt0 .. pt1)
                (curve pt1 .. pt2)
                (curve pt2 .. pt3)
                (curve pt3 .. pt0)))

;; OVALS
(define oval
  (curve (pt 0.5 21  ) ..
         (pt 5   27.5) ..
         (pt 9.5 21  ) ..
         (pt 9.5 20  ) ..
         (pt 9.5 8   ) ..
         (pt 9.5 7   ) ..
         (pt 5   0.5 ) ..
         (pt 0.5 7   ) ..
         (pt 0.5 8   ) ..
         (pt 0.5 20  ) ..
         cycle))


;; SQUIGGLES
(define squiggle
  (curve (pt 1 26) ..
         (pt 3 27) ..
         (pt 9 22) ..
         (pt 8 10) ..
         (pt 9 2 ) ..
         (pt 7 1 ) ..
         (pt 1 6 ) ..
         (pt 2 22) ..
         cycle))


;; Populate the shapes vector
(define curves (list->vector (list diamond oval squiggle)))
(define shades (list->vector
                (list
                 (lambda (shape c h)
                   (with-window shape-window
                     (linewidth 2 (color c (draw shape)))))
                 (lambda (shape c h)
                   (with-window shape-window
                     (linewidth 2 (brush h (color c (filldraw shape))))))
                 (lambda (shape c h)
                   (with-window shape-window
                     (linewidth 2 (draw (color c (fill shape)))))))))

(define (compute-idx i1 i2 i3)
  (+ (* 9 i1) (* 3 i2) i3))

(for* ([color-idx 3]
       [shape-idx 3]
       [shade-idx 3])
  (define c (vector-ref colors color-idx))
  (define hatch (vector-ref hatches color-idx))
  (define shape (vector-ref curves shape-idx))
  (define shade (vector-ref shades shade-idx))

  (vector-set! shapes (compute-idx color-idx shape-idx shade-idx)
               (shade shape c hatch)))