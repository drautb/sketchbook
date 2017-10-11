#lang racket

(define WIDTH 30)
(define HEIGHT 10)

(call-with-output-file
    "random.txt"	 	 	 	 
    (λ (out)
      (define str-contents (make-string (* (add1 WIDTH) HEIGHT) #\.))
      (for ([n (in-range (* (add1 WIDTH) HEIGHT))])
        (if (and (zero? (modulo n (add1 WIDTH)))
                 (> n 0))
            (string-set! str-contents n #\newline)
            (when (< (random 100) 75)
              (string-set! str-contents n #\X))))
      (printf "~a~n" str-contents)
      (write-string str-contents out))
  #:mode 'text
  #:exists 'replace)
 	