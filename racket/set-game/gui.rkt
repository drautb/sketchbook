#lang racket/base

(require racket/gui
         pict
         pict/color
         "card-factory.rkt")


(define frame (new frame%
                   [label "SET"]
                   [width 850]
                   [height 600]))

(define canvas (new canvas% [parent frame]
                    [paint-callback
                     (lambda (canvas dc)
                       (draw-pict (get-card 75) dc 10 10))]))

(send canvas set-canvas-background (send the-color-database find-color "WhiteSmoke"))

(send frame show #t)
