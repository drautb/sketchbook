#lang racket/base

(require racket/list
         graph)

;; Playing with graphs
(define g (directed-graph empty))

(add-vertex! g "[]")
(add-vertex! g "[1]")
(add-vertex! g "[2]")

(add-directed-edge! g "[]" "[1]")
(add-directed-edge! g "[]" "[2]")
(add-directed-edge! g "[1]" "[2]")
(add-directed-edge! g "[2]" "[1]")


(define-edge-property g tap)
(tap-set! "[]" "[1]" "1")
(tap-set! "[]" "[2]" "2")
(tap-set! "[1]" "[2]" "1,2")
(tap-set! "[2]" "[1]" "1,2")

#;(with-output-to-file
  "test-graph.dot"
  (λ ()
    (graphviz g #:output (current-output-port))))


;; Graph generation
(define ns (make-hasheq)) ; neighbors
(hash-set! ns 1 '(2))
(hash-set! ns 2 '(1))

(define (generate-graph ns start)
  (void))

(define (build-node regions)
  (string-append "[" (string-join (map number->string ns) ",") "]"))


;; Highlighted regions - rs
;; touched region - r
(define (transition rs r)
