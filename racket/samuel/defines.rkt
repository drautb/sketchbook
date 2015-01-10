#lang racket

(require racket/draw)

(provide (all-defined-out))

;; Setup our images.
(define BACKGROUND-IMG (make-bitmap 1 1))
(define SAM-IMG (make-bitmap 1 1))
(define NEPHITE-IMG (make-bitmap 1 1))
(define ARROW-IMG (make-bitmap 1 1))

;; Load all the images
(send BACKGROUND-IMG load-file "./img/background.bmp")
(send SAM-IMG load-file "./img/sam.png" 'png/alpha)
(send NEPHITE-IMG load-file "./img/nephite.png" 'png/alpha)
(send ARROW-IMG load-file "./img/arrow.png" 'png/alpha)

;; Constants
(define SCREEN-WIDTH (send BACKGROUND-IMG get-width))
(define SCREEN-HEIGHT (send BACKGROUND-IMG get-height))
(define SCREEN-MID-X (/ SCREEN-WIDTH 2.0))

(define MS-PER-SECOND 1000.0)
(define FRAME-SAMPLE-COUNT 30) ; The number of previous frames to use to calculate FPS.
(define NETWORK-UPDATES-PER-SECOND 15)
(define NETWORK-UPDATE-INTERVAL-MS (/ MS-PER-SECOND NETWORK-UPDATES-PER-SECOND))

(define HOST-PORT 50000)
(define CLIENT-PORT 50001)

(define MENU-FONT-SCALE 2.5)
(define MENU-OPTION-X 125)
(define START-SINGLEPLAYER-Y 150)
(define HOST-MULTIPLAYER-Y 200)
(define JOIN-MULTIPLAYER-Y 250)
(define QUIT-Y 300)

(define SAM-X-VEL 150) ; Velocities are in pixels per second.
(define SAM-Y 84)
(define SAM-WIDTH (send SAM-IMG get-width))
(define SAM-HEIGHT (send SAM-IMG get-height))

(define NEPHITE-Y (- SCREEN-HEIGHT (send NEPHITE-IMG get-height)))
(define NEPHITE-X-VEL 70)
(define NEPHITE-WIDTH (send NEPHITE-IMG get-width))
(define NEPHITE-HEIGHT (send NEPHITE-IMG get-height))

(define ARROW-Y-VEL 400)
(define ARROW-WIDTH (send ARROW-IMG get-width))
(define ARROW-HEIGHT (send ARROW-IMG get-height))

;; Simple game structure, used to transfer data to individual game states
(struct game (state-machine [score #:mutable]
                            [should-quit? #:mutable]
                            [time-delta #:mutable]))

(struct bbox (x y width height) #:prefab #:mutable)
(struct sprite (x-vel y-vel) #:super struct:bbox #:prefab #:mutable)

;; Prophet is a single sam struct
;; Nephites is a list of sprite structs
;; Arrows is a list of sprite structs
(struct world (sam nephites arrows score) #:prefab #:mutable)

(struct cmd (join-host new-x-vel fire-arrow) #:prefab)

(random-seed (current-seconds))

(define (new-world needs-ai?)
  (let ([new-world (world (sprite SCREEN-MID-X SAM-Y SAM-WIDTH SAM-HEIGHT 0 0) null null 0)])
    (if needs-ai?
        (set-world-nephites! new-world
                             (list (sprite (random SCREEN-WIDTH) NEPHITE-Y NEPHITE-WIDTH NEPHITE-HEIGHT 0 0)
                                   (sprite (random SCREEN-WIDTH) NEPHITE-Y NEPHITE-WIDTH NEPHITE-HEIGHT NEPHITE-X-VEL 0)
                                   (sprite (random SCREEN-WIDTH) NEPHITE-Y NEPHITE-WIDTH NEPHITE-HEIGHT (- NEPHITE-X-VEL) 0)))
        (set-world-nephites! new-world
                             (list (sprite (random SCREEN-WIDTH) NEPHITE-Y NEPHITE-WIDTH NEPHITE-HEIGHT 0 0))))
    new-world))

(define (fire-arrow w shooter)
  (set-world-arrows! w
                     (cons (sprite (bbox-x shooter) (bbox-y shooter) ARROW-WIDTH ARROW-HEIGHT 0 (- ARROW-Y-VEL))
                           (world-arrows w))))

(define (tick-sprite s delta-seconds)
  (let ([new-x (+ (bbox-x s) (* (sprite-x-vel s) delta-seconds))]
        [new-y (+ (bbox-y s) (* (sprite-y-vel s) delta-seconds))])
    (when (< new-x 0) (set! new-x SCREEN-WIDTH))
    (when (> new-x SCREEN-WIDTH) (set! new-x 0))
    (set-bbox-x! s new-x)
    (set-bbox-y! s new-y)))

(define (tick-world w delta-seconds)
  (tick-sprite (world-sam w) delta-seconds)
  (for ([n (world-nephites w)])
    (tick-sprite n delta-seconds))
  (for ([a (world-arrows w)])
    (tick-sprite a delta-seconds)
    (when (< (bbox-y a) 0)
      (set-world-score! w (add1 (world-score w)))
      (set-world-arrows! w (remove a (world-arrows w))))))

(define (tick-ai w delta-seconds)
  (let ([sam (world-sam w)]
        [nephites (world-nephites w)]
        [arrows (world-arrows w)])
    (update-seeker (first nephites) sam)
    (for ([n nephites])
      (when (= (random (inexact->exact (truncate (/ 1 (* 5 delta-seconds))))) 0)
        (fire-arrow w n)))))

(define (update-seeker ai target)
  (let ([ai-x (bbox-x ai)][target-x (bbox-x target)])
    (cond [(= ai-x target-x) (set-sprite-x-vel! ai 0)]
          [(< ai-x target-x) (set-sprite-x-vel! ai NEPHITE-X-VEL)]
          [else (set-sprite-x-vel! ai (- NEPHITE-X-VEL))])))

(define (intersect? bbox-1 bbox-2)
  (let* ([min-x1 (bbox-x bbox-1)][min-y1 (bbox-y bbox-1)]
         [max-x1 (+ min-x1 (bbox-width bbox-1))][max-y1 (+ min-y1 (bbox-height bbox-1))]
         [min-x2 (bbox-x bbox-2)][min-y2 (bbox-y bbox-2)]
         [max-x2 (+ min-x2 (bbox-width bbox-2))][max-y2 (+ min-y2 (bbox-height bbox-2))])
    (and (< min-x1 max-x2) (> max-x1 min-x2)
         (< min-y1 max-y2) (> max-y1 min-y2))))

(define (center-is-inside? bbox-1 bbox-2)
  (let ([center-x (+ (bbox-x bbox-1) (/ (bbox-width bbox-1) 2))]
        [center-y (+ (bbox-y bbox-1) (/ (bbox-height bbox-1) 2))])
    (and (> center-x (bbox-x bbox-2))
         (< center-x (+ (bbox-x bbox-2) (bbox-width bbox-2)))
         (> center-y (bbox-y bbox-2))
         (< center-y (+ (bbox-y bbox-2) (bbox-height bbox-2))))))

(define (sam-is-hit? sam arrows)
  (not (for/and ([a arrows])
         (not (center-is-inside? a sam)))))
