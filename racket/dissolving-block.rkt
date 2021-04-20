#lang racket/base

(require racket/gui)

(define WINDOW-WIDTH 640)
(define WINDOW-HEIGHT 480)

(define MS-PER-SECOND 1000)
(define FRAME-SAMPLE-COUNT 30)

(define BLOCK-SIZE 24)

(define BLOCK-IMG (make-bitmap 1 1))
(send BLOCK-IMG load-file "img/block.png")

(define DISSOLVE-MASK-SEQUENCE-IMG (make-bitmap 1 1))
(send DISSOLVE-MASK-SEQUENCE-IMG load-file "img/dissolve-mask.png" 'png/alpha)

(define MASK-IMG (make-bitmap BLOCK-SIZE BLOCK-SIZE))
(define MASK (new bitmap-dc% [bitmap MASK-IMG]))

(define frames '(0))
(define delta 0)

(struct ticker (start interval next-tick ticks max-ticks) #:prefab)

(define the-ticker (ticker (current-process-milliseconds)
                           10
                           (+ 10 (current-process-milliseconds))
                           0
                           31))

(define (update-ticker t)
  (define now (current-process-milliseconds))
  (cond [(>= now (ticker-next-tick t))
         (ticker (ticker-start t)
                 (ticker-interval t)
                 (+ now (ticker-interval t))
                 (if (> (add1 (ticker-ticks t)) (ticker-max-ticks t))
                     0 (add1 (ticker-ticks t)))
                 (ticker-max-ticks t))]
        [else t]))

;; Updates the simulation
(define (tick delta)
  (set! the-ticker (update-ticker the-ticker))
  (define src-x (* (ticker-ticks the-ticker) BLOCK-SIZE))
  (send MASK erase)
  (send MASK draw-bitmap-section
        DISSOLVE-MASK-SEQUENCE-IMG
        0 0
        src-x 0
        BLOCK-SIZE BLOCK-SIZE))

(define (draw-framerate dc frames)
  (when (> (length frames) 1)
    (define start-ms (last frames))
    (define end-ms (first frames))
    (define span-in-seconds (/ (- end-ms start-ms) MS-PER-SECOND))
    (define frames-per-second (/ (- (length frames) 1) span-in-seconds))
    (send dc set-text-foreground "darkgreen")
    (send dc set-brush "white" 'transparent)
    (send dc draw-text (format "FPS: ~a" (truncate frames-per-second)) 10 10)))

;; Draws the simulation
(define (draw-world canvas dc)
  (send dc set-background "black")
  (send dc clear)
  (send dc draw-bitmap DISSOLVE-MASK-SEQUENCE-IMG 0 0)
  (draw-framerate dc frames)
  (send dc draw-bitmap BLOCK-IMG 128 128 'solid
        (send the-color-database find-color "black")
        (send MASK get-bitmap))
  (send dc draw-bitmap (send MASK get-bitmap) 256 128))

;; GUI stuff
(define my-frame (new (class frame% (super-new)
                        (define/augment (on-close) (exit 0)))
                      [label "Dissolving Block"]
                      [width WINDOW-WIDTH]
                      [height WINDOW-HEIGHT]
                      [min-width WINDOW-WIDTH]
                      [min-height WINDOW-HEIGHT]
                      [stretchable-width #f]
                      [stretchable-height #f]
                      [style '(fullscreen-button)]))

(define my-canvas (new canvas% [parent my-frame]
                       [paint-callback draw-world]))

(define (add-frame-time current-time frames)
  (cons current-time (take frames (min FRAME-SAMPLE-COUNT (length frames)))))

(define (main-loop)
  (define start-loop-time (current-milliseconds))
  (set! delta (/ (- start-loop-time (first frames)) MS-PER-SECOND))
  (tick delta)
  (set! frames (add-frame-time (current-milliseconds) frames))

  (send my-canvas refresh-now)
  (yield)
  (flush-output)
  (main-loop))

(send my-frame show #t)
(queue-callback main-loop #f)

