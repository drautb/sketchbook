#lang racket

(define WIDTH 100)
(define HEIGHT 75)

(random-seed 0)

(call-with-output-file
    "random.txt"
    (λ (out)
      (define str-contents (make-string (* (add1 WIDTH) HEIGHT) #\.))
      (for ([n (in-range (* (add1 WIDTH) HEIGHT))])
        (if (and (zero? (modulo n (add1 WIDTH)))
                 (> n 0))
            (string-set! str-contents n #\newline)
            (when (< (random 100) 25)
              (string-set! str-contents n #\X))))
      (write-string str-contents out))
  #:mode 'text
  #:exists 'replace)
