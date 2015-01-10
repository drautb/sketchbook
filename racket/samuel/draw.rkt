#lang racket

(require "defines.rkt")

(provide (all-defined-out))

(define-syntax-rule (keep-transform dc e ...)
                    (begin
                      (define t (send dc get-transformation))
                      (define a (let () e ...))
                      (send dc set-transformation t)
                      a))

(define (draw-world dc w)
  (send dc set-text-foreground "black")
  (send dc erase)
  (send dc draw-bitmap BACKGROUND-IMG 0 0)
  (let ([sam (world-sam w)]
        [nephites (world-nephites w)]
        [arrows (world-arrows w)])
    (send dc draw-bitmap SAM-IMG (bbox-x sam) (bbox-y sam))
    (for ([n nephites])
      (send dc draw-bitmap NEPHITE-IMG (bbox-x n) (bbox-y n)))
    (for ([a arrows])
      (send dc draw-bitmap ARROW-IMG (bbox-x a) (bbox-y a)))
    (send dc draw-text (string-append "Score: " (number->string (world-score w))) 10 10)))

(define (highlight-fatal-arrow dc w)
  (define (find-fatal-arrow sam arrows)
    (if (intersect? sam (first arrows))
        (first arrows)
        (find-fatal-arrow sam (rest arrows))))
  (let* ([sam (world-sam w)]
        [arrows (world-arrows w)]
        [fatal-arrow (find-fatal-arrow sam arrows)])
    (send dc draw-rectangle (bbox-x fatal-arrow) (bbox-y fatal-arrow)
          (bbox-width fatal-arrow) (bbox-height fatal-arrow))))

(define (draw-framerate dc frames)
  (when (> (length frames) 1)
    (send dc set-text-foreground "black")
    (define start-ms (last frames))
    (define end-ms (first frames))
    (define span-in-seconds (/ (- end-ms start-ms) MS-PER-SECOND))
    (define frames-per-second (/ (- (length frames) 1) span-in-seconds))
    (send dc set-pen "yellow" 3 'solid)
    (send dc set-brush "white" 'transparent)
    (send dc draw-text (format "FPS: ~a" (truncate frames-per-second)) 530 10)))
