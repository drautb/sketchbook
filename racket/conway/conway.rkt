#lang racket

(require racket/unsafe/ops)

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
  (for ([row (in-naturals)]
        [row-str row-strs])
    (for ([col (in-naturals)]
          [c (in-string row-str)])
      (bit-worldv-set! current cols row col (not (char=? #\. c)))
      (bit-worldv-set! next cols row col #f)))

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
(define (generate-bitmask n)
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
(define (bit-worldv-set! bwv cols i j ?)
  ;; Locate the byte, then the bit within the byte, then set it.
  (define idx (unsafe-fx+ i (unsafe-fx* cols j)))
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
(define (bit-world-ref bwv cols i j)
  (define idx (unsafe-fx+ i (unsafe-fx* cols j)))
  (define byte-idx (unsafe-fxquotient idx 8))
  (define bit-idx (unsafe-fxmodulo idx 8))
  (not (unsafe-fx= 0 (unsafe-fxand (unsafe-bytes-ref bwv byte-idx) (generate-bitmask bit-idx)))))

(module+ test
  (let ([bwv (make-bytes 10)])
    (check-eq? (bit-world-ref bwv 40 12 1) #f))
  (let ([bwv (make-bytes 10)])
    (unsafe-bytes-set! bwv 7 128)
    (check-eq? (bit-world-ref bwv 40 16 1) #t)))

(define (tick w)
  (void))

(module+ benchmark
  )

(module+ visualizer
  (require 2htdp/universe
           2htdp/image)

  (define SCALE 5)
  (define BOX (square SCALE "solid" "black"))

  (define (draw w)
    (match-define (bit-world rows cols current _) w)
    (for*/fold ([img (empty-scene (* SCALE cols) (* SCALE rows))])
               ([i (in-range rows)]
                [j (in-range cols)])
               (if (bit-world-ref current cols i j)
                   (place-image SCALE
                                (+ (/ SCALE 2) 0.5 (* j SCALE))
                                (+ (/ SCALE 2) 0.5 (* i SCALE))
                                img)
                   img)))

  (big-bang (string->bit-world (port->string (open-input-file "glider.txt")))
            [on-tick tick]
            [on-draw draw]))
