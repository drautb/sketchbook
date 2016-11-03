#lang racket

(require db
         json
         sugar)

(define db-conn (postgresql-connect #:user "drautb" #:database "drautb"))

;; SCHEMA
; (query-exec db-conn "DROP SCHEMA IF EXISTS dss CASCADE")
; (query-exec db-conn "CREATE SCHEMA dss")
(query-exec db-conn "SET SCHEMA 'ds'")
; (query-exec db-conn "CREATE TABLE service (id SERIAL PRIMARY KEY, data JSONB)")
; (query-exec db-conn "CREATE INDEX idx_data on service USING GIN(data)")

;; Random word list
(define WORDLIST (sublist (file->list "/usr/share/dict/words") 0 500))

;; Possible Locations
(define LOCATIONS (list 'production-fh0-va01-primary-1
                        'production-fh0-ut01-secondary-1
                        'production-fh1-useast1-primary-1
                        'production-fh1-uswest2-primary-1
                        'development-fh0-ut01-primary-1
                        'test-fh0-ut01-stable-1
                        'development-fh5-uswest2-primary-1
                        'development-fh5-useast1-primary-1
                        'production-fh1-euwest1-primary-1
                        'test-fh0-ut01-primary-1
                        'test-fh3-useast1-primary-1
                        'test-fh3-uswest2-primary-1))

(define TYPES (list 's3
                    'sqs
                    'beanstalk
                    'rds_postgres
                    'rds_mysql
                    'dynamodb
                    'kinesis
                    'lambda
                    'elasticoder
                    'redis))

;; Get random word
(define (random-element l)
  (let ([len (length l)])
    (symbol->string (list-ref l (random len)))))

;; Generate a random service definition
(define (gen-service-def)
  (jsexpr->string
    (let* ([the-bindings (list (random 500000) (random 500000))]
           [the-hash (make-hash (list (cons 'blueprint (random-element WORDLIST))
                                      (cons 'system (random-element WORDLIST))
                                      (cons 'service (random-element WORDLIST))
                                      (cons 'type (random-element TYPES))
                                      (cons 'location (random-element LOCATIONS))
                                      (cons 'bindings the-bindings)))])
      (when (> (random 100) 65)
        (hash-set! the-hash 'resource (random-element WORDLIST)))
      the-hash)))

(define (insert-new-service service-def)
  (query-exec db-conn
              (string-append "INSERT INTO service(data, create_ts) VALUES('" service-def "', '2013-04-26 21:09:00.000000');")))

; (for ([i 1])
; (for ([i 5])
; (for ([i 60000])
(for ([i 1000000])
  (insert-new-service (gen-service-def)))
(displayln "Inserted 1st million...")

(for ([i 1000000])
  (insert-new-service (gen-service-def)))
(displayln "Inserted 2nd million...")

(for ([i 1000000])
  (insert-new-service (gen-service-def)))
(displayln "Inserted 3rd million...")

(for ([i 1000000])
  (insert-new-service (gen-service-def)))
(displayln "Inserted 4th million...")

(for ([i 1000000])
  (insert-new-service (gen-service-def)))
