#lang racket

;; Stolen from http://stackoverflow.com/questions/23988370/thorough-guide-for-profiling-racket-code

(module mod racket
  (provide f)
  (define (f)
    (for/list ([i 10000])
      i)))

(require (prefix-in mod: 'mod))

(define (f)
  (for ([i 10000])
    (mod:f)))

(require profile)
(profile-thunk f)
