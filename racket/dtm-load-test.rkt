#lang racket

(require json
         net/http-client
         racket/async-channel)

(define SESSION-ID (getenv "FSSESSIONID"))
(define DTM-CFG-HOST (getenv "DTM_CFG_HOST"))
(define DTM-CFG-PORT (string->number (getenv "DTM_CFG_PORT")))
(define FLEETS-PATH "/fleets")

(define OK "HTTP/1.1 200 OK")
(define ACCEPTED "HTTP/1.1 202 Accepted")

(define FLEET-NAME-PREFIX "drautb-test-")

(define THREAD-POOL-SIZE 30)

(define FLEET-CHANNEL (make-async-channel))

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
  (printf "[~a] PUT~n" fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:port DTM-CFG-PORT
                               #:method #"PUT"
                               #:headers (build-headers)
                               #:data (build-fleet-request-body fleet-name))])
    (define status-str (bytes->string/utf-8 status-code))
    (unless (equal? status-str ACCEPTED)
      (error "Failed to PUT fleet. fleetName='~a' response='~a'" fleet-name status-str))))

(define (delete-fleet fleet-name)
  (printf "[~a] DELETE~n" fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:port DTM-CFG-PORT
                               #:method #"DELETE"
                               #:headers (build-headers))])
    (define status-str (bytes->string/utf-8 status-code))
    (unless (equal? status-str ACCEPTED)
      (error "Failed to DELETE fleet. fleetName='~a' response='~a'" fleet-name status-str))))

(define (get-fleet-status fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:port DTM-CFG-PORT
                               #:method #"GET"
                               #:headers (build-headers))])
    (define status-str (bytes->string/utf-8 status-code))
    (if (equal? status-str OK)
        (hash-ref (read-json in-port) 'state)
        ("UNDER_PROCESS")))) ; Pretend it's still under process if the backend goes down for a minute.

(define (wait-for-ready fleet-name)
  (define status (get-fleet-status fleet-name))
  (cond [(equal? status "UNDER_PROCESS")
         (begin
           (printf "[~a] STILL UNDER_PROCESS~n" fleet-name)
           (sleep 5)
           (wait-for-ready fleet-name))]
        [(equal? status "READY")
         (printf "[~a] READY~n" fleet-name)]
        [else
         (printf "[~a] FAILED: '~a'~n" fleet-name status)]))

(define (wait-for-not-found fleet-name)
  (define status (get-fleet-status fleet-name))
  (cond [(equal? status "UNDER_PROCESS")
         (begin
           (printf "[~a] STILL UNDER_PROCESS~n" fleet-name)
           (sleep 5)
           (wait-for-not-found fleet-name))]
        [(equal? status "FLEET_NOT_FOUND")
         (printf "[~a] FLEET_NOT_FOUND~n" fleet-name)]
        [else
         (printf "[~a] FAILED: '~a'~n" fleet-name status)]))


(define (make-dtm-worker action-fn wait-fn)
  (thread
   (lambda ()
     (define (loop)
       (define fleet-name (async-channel-try-get FLEET-CHANNEL))
       (when fleet-name
         (action-fn fleet-name)
         (wait-fn fleet-name)
         (loop)))
     (loop))))

(define (make-fleet-name idx)
  (string-append FLEET-NAME-PREFIX (number->string idx)))

(define (make-fleet-list fleet-count)
  (for/list ([n fleet-count])
    (make-fleet-name n)))

;; ---------------------------------------------------------------------
(define (delete-worker-factory)
  (make-dtm-worker delete-fleet wait-for-not-found))

(define (put-worker-factory)
  (make-dtm-worker put-fleet wait-for-ready))

(define (execute-pool fleet-count worker-factory-fn)
  (define fleet-list (make-fleet-list fleet-count))
  (for ([fleet fleet-list])
    (async-channel-put FLEET-CHANNEL fleet))
  (define threads
    (for/list ([n THREAD-POOL-SIZE])
      (worker-factory-fn)))
  (for ([t threads])
    (thread-wait t)))

(define (delete-fleets fleet-count)
  (execute-pool fleet-count delete-worker-factory))

(define (put-fleets fleet-count)
  (execute-pool fleet-count put-worker-factory))
