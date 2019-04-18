#lang racket/base

(require racket/list
         racket/string
         net/http-client)

(provide get-request
         post-request)

(define (get-request host uri headers)
  (let-values ([(status-code headers in-port)
                (http-sendrecv host
                               uri
                               #:ssl? #t
                               #:method "GET"
                               #:headers headers)])
    (values (status-code->number status-code)
            (headers->hash headers)
            in-port)))

(define (post-request host uri headers data)
  (let-values ([(status-code headers in-port)
                (http-sendrecv host
                               uri
                               #:ssl? #t
                               #:method "POST"
                               #:headers headers
                               #:data data)])
    (values (status-code->number status-code)
            (headers->hash headers)
            in-port)))

(define (status-code->number status-code-bytes)
  (string->number (substring (bytes->string/utf-8 status-code-bytes) 9 12)))

(define (headers->hash headers)
  (define hs (make-hash))
  (for ([h-str headers])
    (define kv (string-split (bytes->string/utf-8 h-str) ": "))
    (define key (first kv))
    (define value (second kv))
    (hash-set! hs key (append (hash-ref hs key empty) (list value))))
  hs)
