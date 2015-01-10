#lang racket

(provide (all-defined-out))

;; Interface for a game state
(define game-state-interface<%>
  (interface ()
    on-enter
    on-tick
    on-exit
    on-char
    on-mouse
    on-draw))

;; No-op state. If the state machine doesn't have a current state, it will return this
;; one so that the normal functions can still be called, but nothing will happen.
(define gs-no-op
  (new (class* object% (game-state-interface<%>) (super-new)
         (define/public (on-enter) (void))
         (define/public (on-tick game) (void))
         (define/public (on-exit) (void))
         (define/public (on-char game event) (void))
         (define/public (on-mouse game event) (void))
         (define/public (on-draw game canvas dc) (void)))))

;; State machine class
;; Maintains a stack of states, calling transition functions
;; when states are pushed or popped.
(define state-machine%
  (class object%
    (super-new)
    (field [states '()])
    (define/public (push new-state)
                   (send new-state on-enter)
                   (set! states (cons new-state states)))
    (define/public (pop)
                   (cond [(empty? states) (void)]
                         [else
                          (send (first states) on-exit)
                          (set! states (rest states))]))
    (define/public (pop-all)
                   (unless (empty? states)
                     (pop) (pop-all)))
    (define/public (current-state)
                   (cond [(empty? states) gs-no-op]
                         [else (first states)]))))
