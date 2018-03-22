#lang racket

(require json
         net/http-client
         racket/date)

(define (get-env name)
  (bytes->string/utf-8 (environment-variables-ref (current-environment-variables) (string->bytes/utf-8 name))))

(define FSSESSIONID (get-env "FSSESSIONID"))
(define DTM-CFG-HOST (get-env "DTM_CFG_HOST"))
(define FLEETS-PATH "/fleets")

(define SIX-MONTHS-AGO (- (current-seconds) 15780000))

(define (build-headers)
  (list (string->bytes/utf-8 (string-append "Authorization: Bearer " FSSESSIONID))))

(define fleets
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               FLEETS-PATH
                               #:method #"GET"
                               #:headers (build-headers))])
    (read-json in-port)))

(define (delete-fleet fleet-name)
  (printf "Deleting fleet '~a'~n" fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:method #"DELETE"
                               #:headers (build-headers))])
    (define status-code-str (bytes->string/utf-8 status-code))
    (if (string-contains? status-code-str "202")
        (printf "Delete accepted for fleet '~a'~n" fleet-name)
        (error 'delete-fleet "Delete failed for fleet '~a', response was ~a~n" fleet-name status-code-str))))

(define (wait-for-fleet-to-disappear fleet-name)
  (printf "Checking status of fleet '~a'...~n" fleet-name)
  (let-values ([(status-code headers in-port)
                (http-sendrecv DTM-CFG-HOST
                               (string-append FLEETS-PATH "/" fleet-name)
                               #:method #"GET"
                               #:headers (build-headers))])
    (define status-code-str (bytes->string/utf-8 status-code))
    (define body (read-json in-port))
    (cond [(string-contains? status-code-str "200")
           (begin
             (printf "Fleet '~a' still exists in state ~a, sleeping for 5 seconds~n"
                     fleet-name (hash-ref body 'state))
             (sleep 5)
             (wait-for-fleet-to-disappear fleet-name))]
          [(string-contains? status-code-str "404")
           (printf "Fleet '~a' has disappeared.~n" fleet-name)]
          [else
           (error 'wait-for-fleet-to-disappear
                  "An unexpected response was received when checking status of fleet ~a, response: ~a, body: ~a~n"
                  fleet-name status-code-str body)])))

(for ([fleet fleets])
  (define fleet-name (hash-ref fleet 'fleetName))
  (if (and (not (hash-ref fleet 'resolves))
           (< (hash-ref fleet 'updated) SIX-MONTHS-AGO))
      (begin
        (delete-fleet fleet-name)
        (wait-for-fleet-to-disappear fleet-name))
      (printf "Skipping fleet '~a'~n" fleet-name)))
