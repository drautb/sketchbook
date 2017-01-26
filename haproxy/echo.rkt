#lang racket

(require json
         web-server/servlet
         web-server/servlet-env)

(define port (make-parameter 8080))

(command-line
  #:program "echo-port"
  #:once-each
  [("-p" "--port") listen-on-port "Port to listen on"
   (port (string->number listen-on-port))])

(define (echo-port request)
  (response/full
    200 #"OK"
    (current-seconds)
    #"application/json; charset=utf-8"
    empty
    (list
      (jsexpr->bytes
        (hash 'port (port)
              'request-headers
              (map (λ (h)
                     (hash (string->symbol (bytes->string/utf-8 (header-field h)))
                           (bytes->string/utf-8 (header-value h))))
                   (request-headers/raw request)))))))

(serve/servlet echo-port
               #:port (port)
               #:servlet-path "/http"
               #:command-line? #t)
