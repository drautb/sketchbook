#lang typed/racket

;; See `quadtree.rkt` for history.
;;
;; "What if I convert everything to typed racket?"

(require typed/racket/gui)

(define NUM-BLOCKS 437)
(define RENDERING 'texture) ;; Should be 'texture 'lines or 'none

(define BLOCK-SIZE 24)

(define BLOCK-IMG (make-bitmap 1 1))
(send BLOCK-IMG load-file "block.png")

(define GRID-WIDTH 23)
(define GRID-HEIGHT 19)

(define WINDOW-WIDTH (inexact->exact (* GRID-WIDTH BLOCK-SIZE)))
(define WINDOW-HEIGHT (inexact->exact (* GRID-HEIGHT BLOCK-SIZE)))

(define BACKBUFFER-IMG (make-bitmap WINDOW-WIDTH WINDOW-HEIGHT))
(define BACKBUFFER (new bitmap-dc% [bitmap BACKBUFFER-IMG]))

(define MS-PER-SECOND 1000.0)
(define FRAME-SAMPLE-COUNT 30)

(define MAX-OBJECTS 10)
(define MAX-LEVELS 5)

(define MIN-BLOCK-PIXELS-PER-SECOND (* 2 BLOCK-SIZE))
(define MAX-BLOCK-PIXELS-PER-SECOND (* 10 BLOCK-SIZE))

(define: frames : (Listof Integer) '(1))
(define delta 0.0)

(define blocks : (Listof block) '())

;; Box struct
(define-type BBox bbox)
(struct: bbox ([x : Float]
               [y : Float]
               [width : Nonnegative-Float]
               [height : Nonnegative-Float]) #:mutable #:transparent)

(define-type Block block)
(struct: block bbox ([colliding : Boolean]
                     [x-vel : Float]
                     [y-vel : Float]) #:mutable #:transparent)

(: intersect? (-> BBox BBox Boolean))
(define (intersect? bbox-1 bbox-2)
  (let* ([min-x1 (bbox-x bbox-1)][min-y1 (bbox-y bbox-1)]
         [max-x1 (+ min-x1 (bbox-width bbox-1))][max-y1 (+ min-y1 (bbox-height bbox-1))]
         [min-x2 (bbox-x bbox-2)][min-y2 (bbox-y bbox-2)]
         [max-x2 (+ min-x2 (bbox-width bbox-2))][max-y2 (+ min-y2 (bbox-height bbox-2))])
    (and (< min-x1 max-x2) (> max-x1 min-x2)
         (< min-y1 max-y2) (> max-y1 min-y2))))

(: draw-bbox (-> (Instance DC<%>) BBox Any))
(define (draw-bbox dc b)
  (send dc draw-rectangle 
        (bbox-x b) 
        (bbox-y b) 
        (bbox-width b)
        (bbox-height b)))

(: draw-block (-> (Instance DC<%>) Block Any))
(define (draw-block dc b)
  (send dc draw-bitmap BLOCK-IMG (bbox-x b) (bbox-y b)))

;; Quadtree node struct.
(define-type Quadtree quadtree)
(struct: quadtree
  ([level : Integer]
   [bounds : BBox]
   [objects : (Listof Block)]
   [nodes : (Listof Quadtree)]) #:mutable #:transparent)

(: new-quadtree (-> Integer BBox Quadtree))
(define (new-quadtree i b)
  (quadtree i b null null))

;; Operations of Quadtrees
(: quadtree-clear (-> Quadtree Any))
(define (quadtree-clear q)
  (set-quadtree-objects! q '())
  (map (λ: ([node : Quadtree])
         (quadtree-clear node))
       (quadtree-nodes q)))

(: quadtree-add-object (-> Quadtree Block Any))
(define (quadtree-add-object q b)
  (set-quadtree-objects! q (cons b (quadtree-objects q))))

(: quadtree-get-index (-> Quadtree BBox Integer))
(define (quadtree-get-index q b)
  (let* ([bounds (quadtree-bounds q)]
         [mid-x (+ (bbox-x bounds) (/ (bbox-width bounds) 2))]
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

(: quadtree-insert (-> Quadtree Block Any))
(define (quadtree-insert q b)
  (let ([index (quadtree-get-index q b)]
        [nodes (quadtree-nodes q)]
        [objects (quadtree-objects q)]
        [current-level (quadtree-level q)])
    (cond [(and (not (empty? nodes)) (not (= -1 index)))
           (quadtree-insert (list-ref nodes index) b)]
          [else (quadtree-add-object q b)
                (when (and (> (length objects) MAX-OBJECTS) (< current-level MAX-LEVELS))
                  (when (empty? nodes) (quadtree-split q))
                  (set-quadtree-objects! q
                                         (map (λ: ([n : Block])
                                                (let ([idx (quadtree-get-index q n)])
                                                  (if (= -1 idx)
                                                      n
                                                      (begin (quadtree-insert (list-ref nodes idx) n) null))))
                                              objects)))])))

(: quadtree-get-candidates (-> Quadtree Block (Listof Block)))
(define (quadtree-get-candidates q b)
  (let ([nodes (quadtree-nodes q)]
        [objects (quadtree-objects q)]
        [idx (quadtree-get-index q b)])
    (if (and (not (= -1 idx)) (not (empty? nodes)))
        (append objects (quadtree-get-candidates (list-ref nodes idx) b))
        objects)))

(: quadtree-draw (-> Quadtree (Instance DC<%>) Any))
(define (quadtree-draw q dc)
  (send dc set-pen "black" 1 'solid)
  (send dc set-brush "white" 'transparent)
  (let ([nodes (quadtree-nodes q)]
        [bounds (quadtree-bounds q)]
        [objects (quadtree-objects q)])
    (when (and (empty? nodes)
               (not (empty? objects)))
      (draw-bbox dc bounds))
    (for ([n (in-list nodes)])
      (quadtree-draw n dc))))

(: quadtree-split (-> Quadtree Any))
(define (quadtree-split q)
  (let* ([bounds (quadtree-bounds q)]
         [new-level (add1 (quadtree-level q))]
         [subwidth (/ (bbox-width bounds) 2.0)]
         [subheight (/ (bbox-height bounds) 2.0)]
         [x (bbox-x bounds)]
         [y (bbox-y bounds)])
    (assert subwidth positive?)
    (assert subheight positive?)
    (set-quadtree-nodes! q
          (list (new-quadtree new-level (bbox x y subwidth subheight))
                (new-quadtree new-level (bbox (+ x subwidth) y subwidth subheight))
                (new-quadtree new-level (bbox (+ x subwidth) (+ y subheight) subwidth subheight))
                (new-quadtree new-level (bbox x (+ y subheight) subwidth subheight))))))

(define my-quadtree (new-quadtree 0 (bbox 0.0 0.0 
                                          (exact->inexact WINDOW-WIDTH)
                                          (exact->inexact WINDOW-HEIGHT))))

(: add-block (-> Any))
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
    (set! blocks (cons (block x y (* 1.0 BLOCK-SIZE) (* 1.0 BLOCK-SIZE) #f x-vel y-vel) blocks))))

;; Updates the simulation
(: tick (-> Float Any))
(define (tick delta)
  (quadtree-clear my-quadtree)
  (for ([b (in-list blocks)])
    (set-block-colliding! b #f)
    (set-bbox-x! b (+ (bbox-x b) (* (block-x-vel b) delta)))
    (set-bbox-y! b (+ (bbox-y b) (* (block-y-vel b) delta)))
    (let* ([x (bbox-x b)][y (bbox-y b)]
           [width (bbox-width b)][height (bbox-height b)]
           [x2 (+ x width)][y2 (+ y height)])
      (cond [(< x 0)
             (set-bbox-x! b 0.0)
             (set-block-x-vel! b (* -1 (block-x-vel b)))]
            [(> x2 WINDOW-WIDTH)
             (set-bbox-x! b (- WINDOW-WIDTH width))
             (set-block-x-vel! b (* -1 (block-x-vel b)))]
            [(< y 0)
             (set-bbox-y! b 0.0)
             (set-block-y-vel! b (* -1 (block-y-vel b)))]
            [(> y2 WINDOW-HEIGHT)
             (set-bbox-y! b (- WINDOW-HEIGHT height))
             (set-block-y-vel! b (* -1 (block-y-vel b)))]))
    (quadtree-insert my-quadtree b))
  (for ([b (in-list blocks)])
    (let ([candidates (remove b (quadtree-get-candidates my-quadtree b))])
      (for ([b2 (in-list candidates)])
        (when (intersect? b b2)
          (set-block-colliding! b #t)
          (set-block-colliding! b2 #t))))))

(: draw-framerate (-> (Instance Bitmap-DC%) (Listof Integer) Any))
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
(: draw-world (-> (Instance Canvas%) (Instance DC<%>) Any))
(define (draw-world canvas dc)
  (send BACKBUFFER clear)
  (unless (eq? RENDERING 'none)
    (when (eq? RENDERING 'lines) (quadtree-draw my-quadtree BACKBUFFER))
    (if (eq? RENDERING 'lines)
        (begin (send BACKBUFFER set-brush "white" 'transparent)
               (for ([b (in-list blocks)])
                 (send BACKBUFFER set-pen "blue" 1 'solid)
                 (when (block-colliding b) (send BACKBUFFER set-pen "red" 1 'solid))
                 (draw-bbox BACKBUFFER b)))
        (begin (for ([b (in-list blocks)])
                 (draw-block BACKBUFFER b)))))
  (draw-framerate BACKBUFFER frames)
  (send dc draw-bitmap BACKBUFFER-IMG 0 0))

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

(: add-frame-time (-> Integer (Listof Integer) (Listof Integer)))
(define (add-frame-time current-time frames)
  (cons current-time (take frames (min FRAME-SAMPLE-COUNT (length frames)))))

(: main-loop (-> Any))
(define (main-loop)
  (define: start-loop-time : Float (exact->inexact (current-milliseconds)))
  (set! delta (/ (- start-loop-time (first frames)) MS-PER-SECOND))
  (tick delta)
  (set! frames (add-frame-time (current-milliseconds) frames))

  (send my-canvas refresh-now)
  (yield)
  (flush-output)
  (main-loop))

(let ([s (current-seconds)])
  (assert s positive?)
  (random-seed s))

(for ([n NUM-BLOCKS])
  (add-block))

(send my-frame show #t)
(queue-callback main-loop #f)
