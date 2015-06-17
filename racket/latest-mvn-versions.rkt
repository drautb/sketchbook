#!/usr/bin/env racket

#lang racket

(require net/http-client
         xml
         xml/path)

(define HOST "mvn.fsglobal.net")
(define COLUMN-WIDTH 30)

(define ARTIFACTS
  (list "paas-sps-context"
        "paas-sps-common"
        "paas-sps-common-test"
        "paas-sps-config"
        "paas-sps-launcher"
        "paas-sysps-context"))

(define (build-request-path repository group artifact version)
  (string-append "/service/local/artifact/maven?r=" repository "&g=" group "&a=" artifact "&v=" version))

(define (execute-request path)
  (let-values ([(status-code header in-port) (http-sendrecv HOST path)])
    (xml->xexpr (document-element (read-xml in-port)))))

(define (fetch-latest-artifact-version artifact)
  (let* ([path (build-request-path "approved" "org.familysearch.paas" artifact "RELEASE")]
         [response (execute-request path)])
    (se-path* '(project version) response)))

(define (build-format-str a)
  (string-append "~a" (make-string (- COLUMN-WIDTH (string-length a)) #\space) "~a~n"))

(define (show-latest-version-for-artifacts artifacts)
  (for ([a artifacts])
    (let ([format-str (build-format-str a)])
      (printf format-str a (fetch-latest-artifact-version a)))))

(show-latest-version-for-artifacts ARTIFACTS)


