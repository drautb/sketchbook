#lang racket

(require 2htdp/image
         2htdp/universe)

(define background-img (bitmap/file "./background.bmp"))
(define sam-img (bitmap/file "./sam.bmp"))

(define SCREEN-WIDTH 640)
(define SCREEN-HEIGHT 480)

(struct samuel (x y))

(struct world (samuel))

(define (generate-world-img w)
  background-img)

(big-bang (world (samuel 300 100))
          (to-draw generate-world-img SCREEN-WIDTH SCREEN-HEIGHT))
