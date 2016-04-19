#!/usr/bin/env racket

#lang racket

(require net/http-client
         json)

(define PORTAL-HOST "dptservices.familysearch.org")
(define AUTH-PATH "/portal/portal-sessions/current/aws-sessions")

(match-define (list JSESSIONID FSPSESSIONID MFA-SESSION)
  (vector->list (current-command-line-arguments)))

(define ACCOUNTS (list '("vpcdesign-fh4" . "SuperAdmin")
                       '("playground-fh2" . "SuperAdmin")
                       '("development-fh5" . "SuperAdmin")
                       '("test-fh3" . "SuperAdmin")
                       '("production-fh1" . "SuperAdmin")))

(define (get-credentials info)
  (define account (car info))
  (define group (cdr info))
  (define (build-data)
    (define o (open-output-string))
    (write-json (make-hash (list (cons 'account account)
                                 (cons 'group group)))
                o)
    (get-output-string o)) 
  (define (build-headers)
    (list (string->bytes/utf-8 (string-append "MFA-Session: " MFA-SESSION))
          (string->bytes/utf-8 (string-append "Cookie: JSESSIONID=" JSESSIONID "; fspSessionId=" FSPSESSIONID))
          (string->bytes/utf-8 (string-append "Content-Type: application/familysearch-paas-portal-aws-session-v1+json"))))
  (let-values ([(status-code headers in-port) (http-sendrecv PORTAL-HOST
                                                             AUTH-PATH
                                                             #:method #"POST"
                                                             #:headers (build-headers)
                                                             #:data (build-data))])
    (read-json in-port)))

(define (generate-output-file data-hash)
  (define account-name (hash-ref data-hash 'account))
  (define password (hash-ref data-hash 'password))
  (define access-key (hash-ref data-hash 'accessKey))
  (define secret-key (hash-ref data-hash 'secretKey))
  (define filename (string-append account-name "-env"))
  (define of (open-output-file (expand-user-path (string-append "~/" filename))
                               #:mode 'text #:exists 'truncate))
  (write-string (string-append "export AWS_ACCOUNT_NAME=\"" account-name "\"\n") of)
  (write-string "export AWS_USERNAME=\"drautb\"\n" of)
  (write-string (string-append "export AWS_PASSWORD=\"" (string-replace password "\"" "\\\"") "\"\n") of)
  (write-string (string-append "export AWS_ACCESS_KEY_ID=\"" access-key "\"\n") of)
  (write-string (string-append "export AWS_SECRET_KEY=\"" secret-key "\"\n") of)
  (write-string (string-append "export AWS_SECRET_ACCESS_KEY=\"" secret-key "\"\n") of)
  (write-string "export AWS_DEFAULT_REGION=\"us-east-1\"\n" of)
  (write-string (string-append "export AWS_LOGIN_URL=\"https://" account-name ".signin.aws.amazon.com/console?region=us-east-1\"\n") of)
  (close-output-port of))

(for ([account ACCOUNTS])
  (generate-output-file (get-credentials account)))
