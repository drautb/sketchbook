#lang racket

;; This is a study for Greebles in which I implemented a Quadtree
;; for fast collision detection.

(require racket/gui
         racket/performance-hint
         profile
         ; profile/render-graphviz)
         profile/render-text)

(define BLOCK-SIZE 24)

(define GRID-WIDTH 23)
(define GRID-HEIGHT 19)

(define WINDOW-WIDTH (* GRID-WIDTH BLOCK-SIZE))
(define WINDOW-HEIGHT (* GRID-HEIGHT BLOCK-SIZE))

(define MS-PER-SECOND 1000)
(define FRAME-SAMPLE-COUNT 30)

(define MAX-OBJECTS 10)
(define MAX-LEVELS 5)

(define NUM-BLOCKS 250)
(define MIN-BLOCK-PIXELS-PER-SECOND (* 2 BLOCK-SIZE))
(define MAX-BLOCK-PIXELS-PER-SECOND (* 10 BLOCK-SIZE))

(define frames '(0))
(define delta 0)

(define blocks '())

;; Box struct
(struct bbox (x y width height) #:mutable #:transparent)

(struct block (colliding x-vel y-vel) #:super struct:bbox #:mutable #:transparent)

(define-inline (intersect? bbox-1 bbox-2)
  (let* ([min-x1 (bbox-x bbox-1)][min-y1 (bbox-y bbox-1)]
                                 [max-x1 (+ min-x1 (bbox-width bbox-1))][max-y1 (+ min-y1 (bbox-height bbox-1))]
                                 [min-x2 (bbox-x bbox-2)][min-y2 (bbox-y bbox-2)]
                                 [max-x2 (+ min-x2 (bbox-width bbox-2))][max-y2 (+ min-y2 (bbox-height bbox-2))])
    (and (< min-x1 max-x2) (> max-x1 min-x2)
         (< min-y1 max-y2) (> max-y1 min-y2))))

(define (draw-bbox dc b)
  (send dc draw-rectangle (bbox-x b) (bbox-y b) (bbox-width b) (bbox-height b)))

;; Quadtree Node Class
(define quadtree%
  (class object% (super-new)
    (init level)
    (init bounding-box)

    (define current-level level)
    (define bounds bounding-box)
    (define objects '())
    (define nodes '())

    (define/public (clear)
      (set! objects '())
      (map (λ (node)
             (send node clear))
           nodes))
    (define/public (insert b)
      (let ([index (get-index b)])
        (cond [(and (not (empty? nodes)) (not (= -1 index)))
               (send (list-ref nodes index) insert b)]
              [else (add-object b)
                    (when (and (> (length objects) MAX-OBJECTS) (< current-level MAX-LEVELS))
                      (when (empty? nodes) (split))
                      (set! objects
                            (remove* (list null) (map (begin-encourage-inline (λ (n)
                                                        (let ([idx (get-index n)])
                                                          (if (= -1 idx)
                                                              n
                                                              (begin (send (list-ref nodes idx) insert n) null)))))
                                                      objects))))])))
    (define/public (get-candidates b)
      (let ([idx (get-index b)])
        (if (and (not (= -1 idx)) (not (empty? nodes)))
            (append objects (send (list-ref nodes idx) get-candidates b))
            objects)))
    (define/public (draw dc)
      (send dc set-pen "black" 1 'solid)
      (send dc set-brush "white" 'transparent)
      (when (and (empty? nodes)
                 (not (empty? objects)))
        (draw-bbox dc bounds))
      (for ([n (in-list nodes)])
        (send n draw dc)))

    (define/private (split)
      (let ([new-level (add1 current-level)]
            [subwidth (/ (bbox-width bounds) 2)]
            [subheight (/ (bbox-height bounds) 2)]
            [x (bbox-x bounds)]
            [y (bbox-y bounds)])
        (set! nodes
              (list (new quadtree% [level new-level][bounding-box (bbox x y subwidth subheight)])
                    (new quadtree% [level new-level][bounding-box (bbox (+ x subwidth) y subwidth subheight)])
                    (new quadtree% [level new-level][bounding-box (bbox (+ x subwidth) (+ y subheight) subwidth subheight)])
                    (new quadtree% [level new-level][bounding-box (bbox x (+ y subheight) subwidth subheight)])))))
    (define/private (get-index b)
      (let* ([mid-x (+ (bbox-x bounds) (/ (bbox-width bounds) 2))]
             [mid-y (+ (bbox-y bounds) (/ (bbox-height bounds) 2))]
             [x (bbox-x b)][y (bbox-y b)]
             [x2 (+ x (bbox-width b))][y2 (+ y (bbox-height b))]
             [top-half (and (< y mid-y) (< y2 mid-y))]
             [bottom-half (> y mid-y)]
             [left-half (and (< x mid-x) (< x2 mid-x))]
             [right-half (> x mid-x)])
        (cond [(and top-half left-half) 0]
              [(and top-half right-half) 1]
              [(and bottom-half right-half) 2]
              [(and bottom-half left-half) 3]
              [else -1])))
    (define/private (add-object bbox)
      (set! objects (cons bbox objects)))))

(define my-quadtree (new quadtree%
                         [level 0]
                         [bounding-box (bbox 0 0 WINDOW-WIDTH WINDOW-HEIGHT)]))

(define (add-block)
  (let* ([x (exact->inexact (* BLOCK-SIZE (random GRID-WIDTH)))]
         [y (exact->inexact (* BLOCK-SIZE (random GRID-HEIGHT)))]
         [vel-direction (random 4)]
         [vel (exact->inexact (+ MIN-BLOCK-PIXELS-PER-SECOND (random MAX-BLOCK-PIXELS-PER-SECOND)))]
         [x-vel 0.0][y-vel 0.0])
    (cond [(= 0 vel-direction) (set! x-vel (* -1 vel))]
          [(= 1 vel-direction) (set! x-vel vel)]
          [(= 2 vel-direction) (set! y-vel (* -1 vel))]
          [(= 3 vel-direction) (set! y-vel vel)])
    (set! blocks (cons (block x y BLOCK-SIZE BLOCK-SIZE #f x-vel y-vel) blocks))))

;; Updates the simulation
(define (tick delta)
  (send my-quadtree clear)
  (for ([b (in-list blocks)])
    (set-block-colliding! b #f)
    (set-bbox-x! b (+ (bbox-x b) (* (block-x-vel b) delta)))
    (set-bbox-y! b (+ (bbox-y b) (* (block-y-vel b) delta)))
    (let* ([x (bbox-x b)][y (bbox-y b)]
                         [width (bbox-width b)][height (bbox-height b)]
                         [x2 (+ x width)][y2 (+ y height)])
      (cond [(< x 0)
             (set-bbox-x! b 0)
             (set-block-x-vel! b (* -1 (block-x-vel b)))]
            [(> x2 WINDOW-WIDTH)
             (set-bbox-x! b (- WINDOW-WIDTH width))
             (set-block-x-vel! b (* -1 (block-x-vel b)))]
            [(< y 0)
             (set-bbox-y! b 0)
             (set-block-y-vel! b (* -1 (block-y-vel b)))]
            [(> y2 WINDOW-HEIGHT)
             (set-bbox-y! b (- WINDOW-HEIGHT height))
             (set-block-y-vel! b (* -1 (block-y-vel b)))]))
    (send my-quadtree insert b))
  (for ([b (in-list blocks)])
    (let ([candidates (remove b (send my-quadtree get-candidates b))])
      (for ([b2 (in-list candidates)])
        (when (intersect? b b2)
          (set-block-colliding! b #t)
          (set-block-colliding! b2 #t))))))

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
  (send my-quadtree draw dc)
  (send dc set-brush "white" 'transparent)
  (for ([b (in-list blocks)])
    (send dc set-pen "blue" 1 'solid)
    (when (block-colliding b) (send dc set-pen "red" 1 'solid))
    (draw-bbox dc b))
  (draw-framerate dc frames))

;; GUI stuff
(define my-frame (new (class frame% (super-new)
                        (define/augment (on-close) (exit 0)))
                      [label "Quadtree Demo"]
                      [width WINDOW-WIDTH]
                      [height WINDOW-HEIGHT]
                      [min-width WINDOW-WIDTH]
                      [min-height WINDOW-HEIGHT]
                      [stretchable-width #f]
                      [stretchable-height #f]))

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

(define (run-profiler [repetitions 1])
  (profile-thunk (thunk (tick 0.001))
                 #:repeat repetitions
                 #:render render))

(random-seed (current-seconds))

(for ([n NUM-BLOCKS])
  (add-block))

;; UNCOMMENT THESE TWO LINES TO RUN THE SIMULATION
(send my-frame show #t)
(queue-callback main-loop #f)

;; UNCOMMENT THIS LINE TO RUN THE PROFILER
; (run-profiler 10000)
