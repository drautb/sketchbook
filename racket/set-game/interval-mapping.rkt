#lang racket/base

(require racket/list)

(provide card->components)

;; card->components -> number -> (values number number number number)
;; Given a card number from [0, 81), return the constituent values for
;; The color, shading, shape, and count.
(define (card->components card)
  (extract-components card (list 3 3 3 3)))


(define (extract-components n intervals)
  (if (empty? intervals)
      empty
      (cons (modulo n (first intervals))
            (extract-components (quotient n (first intervals))
                                (rest intervals)))))


(module+ rackunit
  (require rackunit)

  (check-equal? (card->components 0) (list 0 0 0 0))
  (check-equal? (card->components 1) (list 1 0 0 0))
  (check-equal? (card->components 2) (list 2 0 0 0))
  (check-equal? (card->components 3) (list 0 1 0 0))
  (check-equal? (card->components 4) (list 1 1 0 0))
  (check-equal? (card->components 5) (list 2 1 0 0))

  (check-equal? (card->components 79) (list 1 2 2 2))
  (check-equal? (card->components 80) (list 2 2 2 2))
)
