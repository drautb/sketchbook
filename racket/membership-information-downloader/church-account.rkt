#lang racket/base

(require racket/list
         racket/port
         json
         "request.rkt")

(provide get-household-info)


(define (get-household-info token unit-id)
  (let-values ([(status-code headers in-port)
                (get-request "directory.churchofjesuschrist.org"
                             (format "/api/v4/households?unit=~a" unit-id)
                             (standard-headers token))])
    (unless (eq? 200 status-code)
      (error (format "Non-200 response received. ~a~n~a~n~n~a"
                     status-code
                     headers
                     (port->string in-port))))
    (read-json in-port)))


(define (standard-headers token)
  (list "Accept: */*"
        (format "Cookie: directory_access_token=~a" token)))