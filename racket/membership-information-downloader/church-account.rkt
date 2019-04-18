#lang racket/base

(require racket/list
         racket/port
         json
         "request.rkt")

(provide login
         get-unit-id
         get-household-ids
         get-household-info)


(define (login username password)
  (let-values ([(status headers in-port)
                (post-request "signin.lds.org"
                              "/login.html"
                              empty
                              (format "username=~a&password=~a" username password))])
    (format "Cookie: ~a" (first (hash-ref headers "Set-Cookie")))))


(define (get-unit-id login-cookie)
  (let-values ([(status headers in-port)
                (get-request "www.lds.org"
                             "/directory/services/web/v3.0/unit/current-user-units/"
                             (standard-headers login-cookie))])
    (define data (read-json in-port))
    (define home-ward-id #f)
    (for ([stake data])
      (for ([ward (hash-ref stake 'wards)])
        (when (hash-ref ward 'usersHomeWard)
          (set! home-ward-id (hash-ref ward 'wardUnitNo)))))
    (number->string home-ward-id)))


(define (get-member-data login-cookie unit-id)
  (let-values ([(status-code headers in-port)
                (get-request "www.lds.org"
                             (format "/directory/services/web/v3.0/mem/member-list/~a" unit-id)
                             (standard-headers login-cookie))])
    (read-json in-port)))


(define (get-household-ids login-cookie unit-id)
  (define member-data (get-member-data login-cookie unit-id))
  (map (lambda (household)
         (number->string (hash-ref household 'headOfHouseIndividualId)))
       member-data))


(define (get-household-info login-cookie household-id)
  (let-values ([(status-code headers in-port)
                (get-request "www.lds.org"
                             (format "/directory/services/web/v3.0/mem/householdProfile/~a" household-id)
                             (standard-headers login-cookie))])
    (read-json in-port)))


(define (standard-headers login-cookie)
  (list "Accept: application/json"
        login-cookie))