#lang racket

(define lines (file->lines "haproxy.cfg"))

(define last-fleet-name "")

(define munged-lines
  (for/list ([line lines])
    (let ([match-result (regexp-match #px"^backend [A-Za-z0-9.]*:(.*)$" line)])
      (when match-result (set! last-fleet-name
                               (regexp-replace* #px"[^A-Za-z_.-]"
                                                (second match-result)
                                                ""))))
    (string-replace line
                    "server-template srv"
                    (string-append "server-template " last-fleet-name))))

(for ([line munged-lines])
  (displayln line))
