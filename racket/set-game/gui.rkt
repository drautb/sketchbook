#lang racket/base

(require racket/gui
         pict
         pict/color
         "card-factory.rkt")


(define frame (new frame%
                   [label "SET"]
                   [min-width 900]
                   [min-height 600]
                   [style (list 'no-resize-border)]))

(define (draw-board canvas dc)
  (for* ([x (list 20 240 460 680)]
         [y (list 20 160 300)])
    (draw-pict (get-card (random 0 81)) dc x y)))


(define main-panel (new vertical-panel%
                        [parent frame]))

(define canvas-panel (new horizontal-panel%
                          [parent main-panel]))

(define canvas (new canvas%
                    [parent canvas-panel]
                    [min-width 900]
                    [min-height 320]
                    [stretchable-width 900]
                    [stretchable-height 320]
                    [paint-callback draw-board]))

(define speech-btns-panel (new horizontal-panel%
                               [parent main-panel]))

(define speech-panel (new group-box-panel%
                          [parent speech-btns-panel]
                          [horiz-margin 10]
                          [vert-margin 10]
                          [min-width 400]
                          [label "Prompt"]))

(define speech (new message%
                    [parent speech-panel]
                    [label "Welcome to SET!"]))

(define btn-panel (new vertical-panel%
                       [parent speech-btns-panel]
                       [horiz-margin 10]
                       [vert-margin 10]))

(define new-game-btn (new button%
                          [parent btn-panel]
                          [label "New Game"]))

(define draw-btn (new button%
                      [parent btn-panel]
                      [label "Draw Cards"]))

(define shuffle-btn (new button%
                         [parent btn-panel]
                         [label "Shuffle Board"]))

(define hint-btn (new button%
                      [parent btn-panel]
                      [label "Hint"]))


(send canvas set-canvas-background (send the-color-database find-color "WhiteSmoke"))
(send frame show #t)
