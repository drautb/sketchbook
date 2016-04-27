#lang racket

(require db
         json
         sugar)

;; Database connection: localhost:3306
(define db-conn (mysql-connect #:user "root" #:password "password"))

;; SCHEMA
(query-exec db-conn "DROP DATABASE IF EXISTS dss")
(query-exec db-conn "CREATE DATABASE dss")
(query-exec db-conn "USE dss")
(query-exec db-conn (string-append "CREATE TABLE services ("
                                   "id INT PRIMARY KEY AUTO_INCREMENT,"
                                   "data JSON,"
                                   "blueprint TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.blueprint'))),"
                                   "system TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.system'))),"
                                   "service TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.service'))),"
                                   "type TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.type'))),"
                                   "location TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.location'))),"
                                   "resource TEXT GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(data, '$.resource'))),"
                                   "INDEX b (blueprint(32)),"
                                   "INDEX sys (system(10)),"
                                   "INDEX ser (service(32)),"
                                   "INDEX t (type(16)),"
                                   "INDEX l (location(64)),"
                                   "INDEX r (resource(16))"
                                   ")"))

;; Random word list
(define WORDLIST (sublist (file->list "/usr/share/dict/words") 0 50))

;; Get random word
(define (random-word)
  (let ([len (length WORDLIST)])
    (symbol->string (list-ref WORDLIST (random len)))))

;; Generate a random service definition
(define (gen-service-def)
  (jsexpr->string
    (make-hash (list (cons 'blueprint (random-word))
                     (cons 'system (random-word))
                     (cons 'service (random-word))
                     (cons 'type (random-word))
                     (cons 'location (random-word))
                     (cons 'resource (random-word))
                     (cons 'bindings '())))))

(define (insert-new-service service-def)
  (query-exec db-conn
              (string-append "INSERT INTO services(data) VALUES('" service-def "');")))

; (for ([i 1])
(for ([i 5])
; (for ([i 60000])
  (insert-new-service (gen-service-def)))
