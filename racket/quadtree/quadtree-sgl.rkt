#lang racket

;; This is a continuation of quadtree.rkt. Performance wasn't that great using
;; Racket's native GUI drawing stuff, so I'm seeing what kind of performance we
;; can get by using OpenGl pseudo-directly.

(require racket/performance-hint
         racket/gui
         sgl/gl
         sgl/gl-vectors)


(define NUM-BLOCKS 437)

(define BLOCK-SIZE 24)

(define GRID-WIDTH 23)
(define GRID-HEIGHT 19)

(define WINDOW-WIDTH (* GRID-WIDTH BLOCK-SIZE))
(define WINDOW-HEIGHT (* GRID-HEIGHT BLOCK-SIZE))

(define MAX-OBJECTS 10)
(define MAX-LEVELS 5)

(define MIN-BLOCK-PIXELS-PER-SECOND (* 2 BLOCK-SIZE))
(define MAX-BLOCK-PIXELS-PER-SECOND (* 10 BLOCK-SIZE))

(define MS-PER-SECOND 1000)
(define FRAME-SAMPLE-COUNT 30)

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

(define (draw-block b)
  (glTexCoord2f 0 0)
  (glVertex3f (bbox-x b) (bbox-y b) 0)
  (glTexCoord2f 0 1)
  (glVertex3f (bbox-x b) (+ (bbox-y b) BLOCK-SIZE) 0)
  (glTexCoord2f 1 1)
  (glVertex3f (+ (bbox-x b) BLOCK-SIZE) (+ (bbox-y b) BLOCK-SIZE) 0)
  (glTexCoord2f 1 0)
  (glVertex3f (+ (bbox-x b) BLOCK-SIZE) (bbox-y b) 0))

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
    ; (define/public (draw dc)
    ;                (send dc set-pen "black" 1 'solid)
    ;                (send dc set-brush "white" 'transparent)
    ;                (when (and (empty? nodes)
    ;                           (not (empty? objects)))
    ;                  (draw-bbox dc bounds))
    ;                (for ([n (in-list nodes)])
    ;                  (send n draw dc)))

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

(define (draw-world canvas dc)
  (begin (for ([b (in-list blocks)])
           (draw-block b))))
; (draw-framerate BACKBUFFER frames)))

;; OpenGL Functions
(define (gl-init)
  (let ((res BLOCK-TEXTURE))
    (init-textures 1)
    (unless (gl-load-texture (list-ref res 2) (list-ref res 0) (list-ref res 1)
                             GL_NEAREST GL_NEAREST 0)
      (error "Couldn't load texture"))

    (glColor4d 1 1 1 1)
    (glBlendFunc GL_SRC_ALPHA GL_ONE)

    ;; Standard Init
    (glEnable GL_TEXTURE_2D)
    (glClearColor 1.0 1.0 1.0 1.0)
    (glClearDepth 1)))

(define (gl-resize width height)
  (glViewport 0 0 width height)
  (glMatrixMode GL_PROJECTION)
  (glLoadIdentity)
  (glOrtho 0.0 width height 0.0 -1.0 1.0)
  (glMatrixMode GL_MODELVIEW)
  (glLoadIdentity))

(define *textures* '())

(define (init-textures count)
  (set! *textures* (glGenTextures count)))

(define (bitmap->gl-vector bmp)
  (let* (
         (dc (instantiate bitmap-dc% (bmp)))
         (pixels (* (send bmp get-width) (send bmp get-height)))
         (vec (make-gl-ubyte-vector (* pixels 3)))
         (data (make-bytes (* pixels 4)))
         (i 0))
    (send dc get-argb-pixels 0 0 (send bmp get-width) (send bmp get-height) data)
    (letrec
      ([loop
        (lambda ()
          (when (< i pixels)
            (begin
              (gl-vector-set! vec (* i  3)
                              (bytes-ref data (+ (* i 4) 1)))
              (gl-vector-set! vec (+ (* i 3) 1)
                              (bytes-ref data (+ (* i 4) 2)))
              (gl-vector-set! vec (+ (* i 3) 2)
                              (bytes-ref data (+ (* i 4) 3)))
              (set! i (+ i 1))
              (loop))))])
      (loop))
    (send dc set-bitmap #f)
    (list (send bmp get-width) (send bmp get-height) vec)))

(define (image->gl-vector file)
  (bitmap->gl-vector (make-object bitmap% file 'unknown #f)))

(define (gl-load-texture image-vector width height min-filter mag-filter ix)
  (glBindTexture GL_TEXTURE_2D (gl-vector-ref *textures* ix))
  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MIN_FILTER min-filter)
  (glTexParameteri GL_TEXTURE_2D GL_TEXTURE_MAG_FILTER mag-filter)
  (let* ((new-width 128)
         (new-height 128)
         (new-img-vec (make-gl-ubyte-vector (* new-width new-height 3))))
    (gluScaleImage GL_RGB
                   width height GL_UNSIGNED_BYTE image-vector
                   new-width new-height GL_UNSIGNED_BYTE new-img-vec)
    (if (or (= min-filter GL_LINEAR_MIPMAP_NEAREST)
            (= mag-filter GL_LINEAR_MIPMAP_NEAREST))
        (gluBuild2DMipmaps GL_TEXTURE_2D 3 new-width new-height GL_RGB GL_UNSIGNED_BYTE new-img-vec)
        (glTexImage2D GL_TEXTURE_2D 0 3 new-width new-height 0 GL_RGB GL_UNSIGNED_BYTE new-img-vec))))

(define (get-texture ix)
  (gl-vector-ref *textures* ix))

(define BLOCK-TEXTURE (image->gl-vector "/Users/drautb/GitHub/drautb/sketchbook/racket/quadtree/block.png"))

;; GUI stuff
(define my-frame (new (class frame% (super-new)
                        (define/augment (on-close) (exit 0)))
                      [label "Quadtree - C Style OpenGL"]
                      [width WINDOW-WIDTH]
                      [height WINDOW-HEIGHT]
                      [min-width WINDOW-WIDTH]
                      [min-height WINDOW-HEIGHT]
                      [stretchable-width #f]
                      [stretchable-height #f]))

(define my-gl-canvas
  (new
    (class canvas%
      (inherit refresh
               with-gl-context
               swap-gl-buffers)
      (define init? #f)
      (define/override (on-paint)
                       (with-gl-context
                         (lambda ()
                           (unless init?
                             (gl-init)
                             (set! init? #t))
                           (define start-loop-time (current-milliseconds))
                           (set! delta (/ (- start-loop-time (first frames)) MS-PER-SECOND))
                           (tick delta)
                           (set! frames (add-frame-time (current-milliseconds) frames))
                           (gl-draw-world)
                           (swap-gl-buffers)))
                       (queue-callback (lambda () (refresh)) #f))
      (define/override (on-size w h)
                       (with-gl-context
                         (lambda ()
                           (gl-resize w h)))
                       (refresh))
      (super-new (style '(gl no-autoclear))))
    [parent my-frame]
    [paint-callback draw-world]))

(define (gl-draw-world)
  (glClear (+ GL_COLOR_BUFFER_BIT GL_DEPTH_BUFFER_BIT))
  (glBindTexture GL_TEXTURE_2D (get-texture 0))
  (glBegin GL_QUADS)
  (for ([b (in-list blocks)])
    (draw-block b))
  (glEnd)
  (glFlush))

(define (add-frame-time current-time frames)
  (cons current-time (take frames (min FRAME-SAMPLE-COUNT (length frames)))))

(define (main-loop)
  (define start-loop-time (current-milliseconds))
  (set! delta (/ (- start-loop-time (first frames)) MS-PER-SECOND))
  (tick delta)
  (set! frames (add-frame-time (current-milliseconds) frames))

  (send my-gl-canvas refresh-now)
  (yield)
  (flush-output)
  (main-loop))


(random-seed (current-seconds))

(for ([n NUM-BLOCKS])
  (add-block))

(send (send my-gl-canvas get-dc) get-gl-context)
(send my-frame show #t)

