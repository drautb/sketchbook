#lang racket

(require racket/draw
         "../defines.rkt"
         "../draw.rkt"
         "../state-machine.rkt")

(provide (all-defined-out))

;; Game state for single player mode
(define singleplayer
  (new (class* object% (game-state-interface<%>) (super-new)
         (define current-world null)
         (define/public (on-enter)
                        (set! current-world (new-world #t)))
         (define/public (on-tick game)
                        (let* ([seeker (first (world-nephites current-world))]
                               [sam (world-sam current-world)]
                               [delta (game-time-delta game)])
                          (unless (sam-is-hit? sam (world-arrows current-world))
                            (tick-world current-world delta)
                            (tick-ai current-world delta))))
         (define/public (on-exit) (void))
         (define/public (on-char game event)
                        (let ([key-code (send event get-key-code)]
                              [sam (world-sam current-world)])
                          (cond [(eq? key-code 'escape) (send (game-state-machine game) pop)]
                                [(eq? key-code 'left) (set-sprite-x-vel! sam (- SAM-X-VEL))]
                                [(eq? key-code 'right) (set-sprite-x-vel! sam SAM-X-VEL)]
                                [(eq? key-code 'release)
                                 (when (or (and (eq? (send event get-key-release-code) 'left)
                                                (eq? (sprite-x-vel sam) (- SAM-X-VEL)))
                                           (and (eq? (send event get-key-release-code) 'right)
                                                (eq? (sprite-x-vel sam) SAM-X-VEL)))
                                   (set-sprite-x-vel! sam 0))]
                                [else (void)])))
         (define/public (on-mouse game event) (void))
         (define/public (on-draw game canvas dc)
                        (draw-world dc current-world)
                        (when (sam-is-hit? (world-sam current-world) (world-arrows current-world))
                          (highlight-fatal-arrow dc current-world))))))
