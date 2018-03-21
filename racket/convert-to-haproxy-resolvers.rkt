#lang racket

(define lines (file->lines "haproxy.cfg"))

(define last-hostname "")

(define munged-lines
  (for/list ([line lines])
    (let ([match-result (regexp-match #px"\\s# (.*:\\d+)$" line)])
      (when match-result (set! last-hostname (second match-result))))
    (if (regexp-match #px"^\\s+server\\s+.*\\s+[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}:[0-9]{1,6}\\s+.*$" line)
        (string-append
          (regexp-replace #px"[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}:[0-9]{1,6}" line last-hostname)
          " resolvers fs_resolvers resolve-prefer ipv4")
        line)))

(for ([line munged-lines])
  (displayln line))


