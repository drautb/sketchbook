#lang racket/base

(require racket/gui
         pict
         pict/color
         "card-factory.rkt")

(define CANVAS-WIDTH 900)
(define CANVAS-HEIGHT 440)

(define frame (new frame%
                   [label "SET"]))

(define (draw-board canvas dc)
  (for* ([x (list 20 240 460 680)]
         [y (list 20 160 300)])
    (draw-pict (get-card (random 0 81)) dc x y)))


(define main-panel (new vertical-panel%
                        [parent frame]
                        [alignment '(left center)]
                        [stretchable-width #f]
                        [stretchable-height #f]))

(define canvas-panel (new horizontal-panel%
                          [parent main-panel]))

(define canvas (new canvas%
                    [parent canvas-panel]
                    [style '(border)]
                    [min-width CANVAS-WIDTH]
                    [min-height CANVAS-HEIGHT]
                    [paint-callback draw-board]))

(define tools-panel (new horizontal-panel%
                         [parent main-panel]))

(define left-panel (new vertical-panel%
                        [parent tools-panel]))

(define center-panel (new vertical-panel%
                          [parent tools-panel]))

(define right-panel (new vertical-panel%
                         [parent tools-panel]))

;; LEFT PANEL
(define deck-canvas (new canvas%
                         [parent left-panel]
                         [horiz-margin 10]
                         [vert-margin 10]
                         [min-width CARD-WIDTH]
                         [min-height CARD-HEIGHT]
                         [stretchable-width #f]
                         [stretchable-height #f]
                         [paint-callback (λ (canvas dc)
                                           (draw-pict (get-card-back) dc 0 0))]))


;; CENTER PANEL
(define score-panel (new horizontal-panel%
                         [parent center-panel]
                         [alignment '(left center)]))

(define score-label (new message%
                         [parent score-panel]
                         [label "Score:"]))

(define score-value (new message%
                         [parent score-panel]
                         [label "0"]))

(define speech-panel (new group-box-panel%
                          [parent center-panel]
                          [horiz-margin 10]
                          [vert-margin 10]
                          [label "Help"]))

(define speech (new message%
                    [parent speech-panel]
                    [label "Welcome to SET!"]))


;; RIGHT PANEL
(define btn-panel (new vertical-panel%
                       [parent tools-panel]
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
(send deck-canvas set-canvas-background (send the-color-database find-color "Gray"))
(send frame show #t)
