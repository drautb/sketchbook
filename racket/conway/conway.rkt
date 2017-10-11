#lang racket

(require racket/unsafe/ops
         racket/performance-hint
         2htdp/image
         2htdp/universe)

(struct bit-world (rows cols current next) #:mutable)

(define (string->bit-world str)
  (local-require racket/string)
  (define row-strs (string-split str))
  (define rows (length row-strs))
  (define cols (apply max (map string-length row-strs)))

  (define current (make-bit-worldv rows cols))
  (define next (make-bit-worldv rows cols))

  ;; For each row, iterate over each character. If the character is NOT '.', then flip the bit.
  ;; Need numeric indices for row and colum.
  (for ([y (in-naturals)]
        [row-str row-strs])
    (for ([x (in-naturals)]
          [c (in-string row-str)])
      (bit-worldv-set! current cols x y (not (char=? #\. c)))
      (bit-worldv-set! next cols x y #f)))

  (bit-world rows cols current next))

;; Computes the number of required bytes for storing n bits of data.
(define (compute-required-bytes n)
  (let ([n-bytes (quotient n 8)]
        [rem (modulo n 8)])
    (if (zero? rem)
        n-bytes
        (add1 n-bytes))))

(module+ test
  (require rackunit)
  (check-eq? (compute-required-bytes 2) 1)
  (check-eq? (compute-required-bytes 8) 1)
  (check-eq? (compute-required-bytes 17) 3))

;; Generate a mask for a particular digit in a byte, with digits counting from left to right. (0 - 7)
(define-inline (generate-bitmask n)
  (define mask 2)
  (cond [(unsafe-fx= n 6) mask]
        [(unsafe-fx< n 6) (unsafe-fxlshift mask (- 6 n))]
        [else (unsafe-fxrshift mask (- 8 n))]))

(module+ test
  (check-eq? (generate-bitmask 0) 128)
  (check-eq? (generate-bitmask 1) 64)
  (check-eq? (generate-bitmask 2) 32)
  (check-eq? (generate-bitmask 3) 16)
  (check-eq? (generate-bitmask 4) 8)
  (check-eq? (generate-bitmask 5) 4)
  (check-eq? (generate-bitmask 6) 2)
  (check-eq? (generate-bitmask 7) 1))

(define (make-bit-worldv rows cols)
  (make-bytes (compute-required-bytes (* rows cols))))

;; Set the state for a particular bit.
(define-inline (bit-worldv-set! bwv cols x y ?)
  ;; Locate the byte, then the bit within the byte, then set it.
  (define idx (unsafe-fx+ x (unsafe-fx* cols y)))
  (define byte-idx (unsafe-fxquotient idx 8))
  (define bit-idx (unsafe-fxmodulo idx 8))
  (define mask (generate-bitmask bit-idx))
  (if ?
      (unsafe-bytes-set! bwv byte-idx (unsafe-fxior (unsafe-bytes-ref bwv byte-idx) mask))
      (unsafe-bytes-set! bwv byte-idx (unsafe-fxand (unsafe-bytes-ref bwv byte-idx) (unsafe-fxnot mask)))))

(module+ test
  (let ([bwv (make-bytes 2)])
    (bit-worldv-set! bwv 8 2 1 #t)
    (check-eq? (unsafe-bytes-ref bwv 1) 32))
  (let ([bwv (make-bytes 4)])
    (unsafe-bytes-set! bwv 3 64)
    (bit-worldv-set! bwv 8 1 3 #f)
    (check-eq? (unsafe-bytes-ref bwv 3) 0)))

;; Query the state for particular bit.
(define-inline (bit-worldv-ref bwv rows cols x y)
  (cond [(or (unsafe-fx< x 0) (unsafe-fx>= x cols)
             (unsafe-fx< y 0) (unsafe-fx>= y rows))
         #f]
        [else
         (define idx (unsafe-fx+ x (unsafe-fx* cols y)))
         (define byte-idx (unsafe-fxquotient idx 8))
         (define bit-idx (unsafe-fxmodulo idx 8))
         (not (unsafe-fx= 0 (unsafe-fxand (unsafe-bytes-ref bwv byte-idx) (generate-bitmask bit-idx))))]))

(module+ test
  (let ([bwv (make-bytes 10)])
    (check-eq? (bit-worldv-ref bwv 2 40 12 1) #f))
  (let ([bwv (make-bytes 10)])
    (unsafe-bytes-set! bwv 7 128)
    (check-eq? (bit-worldv-ref bwv 2 40 16 1) #t)))

(define-inline (count-neighbors bwv rows cols x y)
  (define count 0)
  (for* ([ny (in-range (sub1 y) (+ 2 y))]
         [nx (in-range (sub1 x) (+ 2 x))])
    (unless (and (unsafe-fx= x nx) (unsafe-fx= y ny))
      (set! count (+ count (if (bit-worldv-ref bwv rows cols nx ny) 1 0)))))
  count)

(module+ test
  (let ([bwv (make-bytes 3)]
        [rows 3]
        [cols 8])
    (bit-worldv-set! bwv cols 0 0 #t)
    (bit-worldv-set! bwv cols 1 0 #t)
    (bit-worldv-set! bwv cols 2 0 #t)
    (bit-worldv-set! bwv cols 0 1 #t)
    (bit-worldv-set! bwv cols 2 1 #t)
    (bit-worldv-set! bwv cols 0 2 #t)
    (bit-worldv-set! bwv cols 1 2 #t)
    (bit-worldv-set! bwv cols 2 2 #t)
    (check-eq? (count-neighbors bwv rows cols 0 0) 2)
    (check-eq? (count-neighbors bwv rows cols 1 0) 4)
    (check-eq? (count-neighbors bwv rows cols 2 0) 2)
    (check-eq? (count-neighbors bwv rows cols 0 1) 4)
    (check-eq? (count-neighbors bwv rows cols 1 1) 8)
    (check-eq? (count-neighbors bwv rows cols 2 1) 4)
    (check-eq? (count-neighbors bwv rows cols 0 2) 2)
    (check-eq? (count-neighbors bwv rows cols 1 2) 4)
    (check-eq? (count-neighbors bwv rows cols 2 2) 2)
    (check-eq? (count-neighbors bwv rows cols 6 2) 0)))

(define-inline (lives? populated? neighbor-count)
  (or (and populated? (or (unsafe-fx= neighbor-count 2)
                          (unsafe-fx= neighbor-count 3)))
      (and (not populated?)
           (unsafe-fx= neighbor-count 3))))

(module+ test
  (check-eq? (lives? #f 0) #f)
  (check-eq? (lives? #f 1) #f)
  (check-eq? (lives? #f 2) #f)
  (check-eq? (lives? #f 3) #t)
  (check-eq? (lives? #f 4) #f)
  (check-eq? (lives? #f 5) #f)
  (check-eq? (lives? #f 6) #f)
  (check-eq? (lives? #f 7) #f)
  (check-eq? (lives? #f 8) #f)
  (check-eq? (lives? #t 0) #f)
  (check-eq? (lives? #t 1) #f)
  (check-eq? (lives? #t 2) #t)
  (check-eq? (lives? #t 3) #t)
  (check-eq? (lives? #t 4) #f)
  (check-eq? (lives? #t 5) #f)
  (check-eq? (lives? #t 6) #f)
  (check-eq? (lives? #t 7) #f)
  (check-eq? (lives? #t 8) #f))

(define (tick w)
  (match-define (bit-world rows cols current next) w)
  (for* ([x (in-range cols)]
         [y (in-range rows)])
    (define populated? (bit-worldv-ref current rows cols x y))
    (define neighbor-count (count-neighbors current rows cols x y))
    (define cell-lives? (lives? populated? neighbor-count))
    (bit-worldv-set! next cols x y cell-lives?))
  (set-bit-world-current! w next)
  (set-bit-world-next! w current)
  w)

(module+ test
  (define (check-tick w-str w2-str)
    (define w  (string->bit-world w-str))
    (define w2 (string->bit-world w2-str))
    (define actual-w2 (tick w))
    (define actual (bit-world-current actual-w2))
    (define expected (bit-world-current w2))
    (check-equal? actual expected)
    (unless (equal? actual expected)
      (beside (bit-world->image (string->bit-world w-str) #:label-neighbors #t)
              (bit-world->image actual-w2)
              (bit-world->image w2))))

  (check-tick (string-append "...\n"
                             "...\n"
                             "...\n")
              (string-append "...\n"
                             "...\n"
                             "...\n"))

  (check-tick (string-append "...\n"
                             ".X.\n"
                             "...\n")
              (string-append "...\n"
                             "...\n"
                             "...\n"))

  (check-tick (string-append "...\n"
                             "XXX\n"
                             "...\n")
              (string-append ".X.\n"
                             ".X.\n"
                             ".X.\n"))

  (check-tick (string-append ".X.\n"
                             ".X.\n"
                             ".X.\n")
              (string-append "...\n"
                             "XXX\n"
                             "...\n"))
  )

(define (bit-world->image w #:label-neighbors [lbl? #f])
  (define SCALE 20)
  (define BOX (square SCALE "solid" "black"))
  (match-define (bit-world rows cols current _) w)
  (for*/fold ([img (empty-scene (* SCALE cols) (* SCALE rows))])
             ([x (in-range cols)]
              [y (in-range rows)])
    (if (bit-worldv-ref current rows cols x y)
        (place-image (if lbl?
                         (overlay (text (number->string (count-neighbors current rows cols x y)) SCALE "white")
                                  BOX)
                         BOX)
                     (+ (/ SCALE 2) 0.5 (* x SCALE))
                     (+ (/ SCALE 2) 0.5 (* y SCALE))
                     img)
        (if lbl?
            (overlay
             (place-image
              (text (number->string (count-neighbors current rows cols x y)) SCALE "black")
              (+ (/ SCALE 2) 0.5 (* x SCALE))
              (+ (/ SCALE 2) 0.5 (* y SCALE))
              img)
             img)
            img))))

(module+ benchmark
  ;; Jay's:
  ;;      original: cpu time: 1843 real time: 1842 gc time: 36
  ;; dishv-ref/set: cpu time: 1683 real time: 1682 gc time: 82
  ;;     neighbors: cpu time:  530 real time:  531 gc time: 0

  ;; Mine:
  ;;      original: cpu time: 1655 real time: 1654 gc time: 2
  ;; define-inline: cpu time: 1084 real time: 1083 gc time: 2
  ;;

  (define seed-str
    "........................O...........
    ......................O.O...........
    ............OO......OO............OO
    ...........O...O....OO............OO
    OO........O.....O...OO..............
    OO........O...O.OO....O.O...........
    ..........O.....O.......O...........
    ...........O...O....................
    ............OO......................")

  (define seed (string->bit-world seed-str))
  (collect-garbage)
  (collect-garbage)
  (time
   (for ([i (in-range 10000)])
     (tick seed))))

(module+ visualizer
  (big-bang (string->bit-world (port->string (open-input-file "glider.txt")))
            [on-tick tick]
            [on-draw bit-world->image]))
