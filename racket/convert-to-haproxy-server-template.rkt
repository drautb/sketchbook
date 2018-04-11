#lang racket

(define lines (file->lines "haproxy.cfg"))

(define last-hostname "")

(define munged-lines
  (for/list ([line lines])
    (let ([match-result (regexp-match #px"\\s# (.*:\\d+)$" line)])
      (when match-result (set! last-hostname (second match-result))))
    (define match-result (regexp-match
                           (pregexp (string-append "^\\s+server\\s+(.*)-[a\\d]+\\s+"
                                                   last-hostname "\\s+(.*)$")) line))
    (if match-result
        (string-append "\tserver-template "
                       "srv"
                       " 20 "
                       last-hostname
                       " "
                       (third match-result))
        line)))

(for ([line munged-lines])
  (displayln line))
