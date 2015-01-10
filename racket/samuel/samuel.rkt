#lang racket

(require racket/gui
         "defines.rkt"
         "draw.rkt"
         "state-machine.rkt"
         "game-states/menu.rkt"
         "game-states/singleplayer.rkt")

;; State machine
(define sm (new state-machine%))

(define current-game (game sm 0 #f 0))

(define frames '(0))

(define (add-frame-time current-time frames)
  (cons current-time (take frames (min FRAME-SAMPLE-COUNT (length frames)))))

(define (shutdown)
  (send sm pop-all)
  (exit 0))

;; Custom frame class
;; We do this so that we can shutdown the whole program if the frame is closed.
;; Sauce: http://stackoverflow.com/questions/18684412/how-to-handle-gui-exit-in-racket
(define samuel-frame%
  (class frame% (super-new)
    (define/augment (on-close) (shutdown))))

;; Custom canvas class
;; We do this so that we can override the on-char/event functions
(define wall-canvas%
  (class canvas% (super-new)
    (define/override (on-char event)
                     (send (send sm current-state) on-char current-game event))
    (define/override (on-event event)
                     (send (send sm current-state) on-mouse current-game event))))

(define root-frame (new samuel-frame% [label "Samuel"]
                        [width SCREEN-WIDTH]
                        [height SCREEN-HEIGHT]
                        [min-width SCREEN-WIDTH]
                        [min-height SCREEN-HEIGHT]
                        [stretchable-width #f]
                        [stretchable-height #f]))
(define root-canvas (new wall-canvas% [parent root-frame]
                         [paint-callback (λ (canvas dc)
                                           (send (send sm current-state) on-draw current-game canvas dc)
                                           (draw-framerate dc frames))]))

(define (main-loop)
  (define start-loop-time (current-milliseconds))
  (set-game-time-delta! current-game (/ (- start-loop-time (first frames)) MS-PER-SECOND))
  (send (send sm current-state) on-tick current-game)
  (when (game-should-quit? current-game) (shutdown))
  (set! frames (add-frame-time (current-milliseconds) frames))
  (send root-canvas refresh-now)
  (yield)
  (flush-output)
  (main-loop))

(send root-frame show #t)

;; Start the game.
(send sm push menu)
(queue-callback main-loop #f)
