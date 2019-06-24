
#lang racket/base

(require racket/gui
         pict
         pict/color
         "shapes.rkt")


(define frame (new frame%
                   [label "Shape Generation"]
                   [width 800]
                   [height 600]))

(new canvas% [parent frame]
             [paint-callback
              (lambda (canvas dc)
                (draw-pict (colorize hollow-squiggle-pict "red") dc 10 0)
                (draw-pict filled-squiggle-pict dc 100 0)
                (draw-pict hollow-oval-pict dc 10 100)
                (draw-pict hollow-diamond-pict dc 100 100))])

(send frame show #t)
