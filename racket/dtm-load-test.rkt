#lang racket

(require json
         net/http-client)

(define SESSION-ID (getenv "FSSESSIONID"))
(define DTM-CFG-HOST (getenv "DTM_CFG_HOST"))
(define FLEETS-PATH "/fleets")

(define ACCEPTED "HTTP/1.1 202 Accepted")

(define (build-headers)
  (list (string->bytes/utf-8 (string-append "Authorization: Bearer " SESSION-ID))
        (string->bytes/utf-8 "Content-Type: application/json")))

(define (build-fleet-request-body fleet-name)
  (define data (make-hash))
  (hash-set! data 'urlPath (string-append "/" fleet-name))
  (hash-set! data 'urlReplace "/")
  (hash-set! data 'domain "dtm.dev.fsglobal.org")
  (hash-set! data 'location "development-fh5-useast1-primary-1")
  (hash-set! data 'publicIs "false")
  (hash-set! data 'healthCheck
             (make-hash (list (cons 'uri "HEAD /healthcheck/heartbeat")
                              (cons 'interval "30s")
                              (cons 'rise "1")
                              (cons 'fall "10"))))
  (hash-set! data 'servers (list "dtm-cfg-qa-static.dev.us-east-1.dev.fslocal.org:80"))
  (hash-set! data 'triggerURL "fake")
  (hash-set! data 'triggerRev "also-fake")
  (hash-set! data 'domainHasDynamicPrefix "false")
  (jsexpr->bytes data))

(define (put-fleet fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:method #"PUT"
                               #:headers (build-headers)
                               #:data (build-fleet-request-body fleet-name))])
    (bytes->string/utf-8 status-code)))

(define (delete-fleet fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:method #"DELETE"
                               #:headers (build-headers))])
    (bytes->string/utf-8 status-code)))

(define (get-fleet-status fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:method #"GET"
                               #:headers (build-headers))])
    (hash-ref (read-json in-port) 'state)))

(define (make-dtm-worker fleet-name)
  (thread
   (lambda ()
     (define log
       (lambda args
         (apply printf 
                (string-append "[~a] " (first args) "~n")
                (cons fleet-name (rest args)))))
     (define (wait-for-ready)
       (define status (get-fleet-status fleet-name))
       (cond [(equal? status "UNDER_PROCESS")
              (begin 
                (log "STILL UNDER_PROCESS")
                (sleep 5)
                (wait-for-ready))]
             [(equal? status "READY")
              (log "READY")]
             [else 
              (log "FAILED: '~a'" status)]))
     (log "PUT")
     (define put-result (put-fleet fleet-name))
     (if (equal? put-result ACCEPTED)
         (begin
           (log "ACCEPTED")
           (wait-for-ready))
         (log "Fleet was NOT accepted! '~a'" put-result)))))

(define (make-delete-worker fleet-name)
  (thread 
   (lambda ()
     (define log
       (lambda args
         (apply printf 
                (string-append "[~a] " (first args) "~n")
                (cons fleet-name (rest args)))))
     (define (wait-for-not-found)
       (define status (get-fleet-status fleet-name))
       (cond [(equal? status "UNDER_PROCESS")
              (begin 
                (log "STILL UNDER_PROCESS")
                (sleep 5)
                (wait-for-not-found))]
             [(equal? status "FLEET_NOT_FOUND")
              (log "FLEET_NOT_FOUND")]
             [else 
              (log "FAILED: '~a'" status)]))
     (log "DELETE")
     (define delete-result (delete-fleet fleet-name))
     (if (equal? delete-result ACCEPTED)
         (begin
           (log "ACCEPTED")
           (wait-for-not-found))
         (log "Delete was NOT accepted! '~a'" delete-result)))))


;; ---------------------------------------------------------------------
(define fleet-count 150)

(define (delete-fleets)
  (define threads
    (for/list ([n fleet-count])
      (make-delete-worker (string-append "drautb-test-" (number->string n)))))
  (for ([t threads])
    (thread-wait t)))

(define (create-fleets)
  (define threads 
    (for/list ([n fleet-count])
      (make-dtm-worker (string-append "drautb-test-" (number->string n)))))
  (for ([t threads])
    (thread-wait t)))


