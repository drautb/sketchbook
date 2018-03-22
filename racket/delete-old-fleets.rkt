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

(for ([fleet fleets])
  (define fleet-name (hash-ref fleet 'fleetName))
  (if (and (not (hash-ref fleet 'resolves))
           (< (hash-ref fleet 'updated) SIX-MONTHS-AGO))
      (begin
        (printf "Deleting fleet '~a'~n" fleet-name)
        (delete-fleet fleet-name)
        (wait-for-fleet-to-disappear fleet-name))
      (printf "Skipping fleet '~a'~n" fleet-name)))
