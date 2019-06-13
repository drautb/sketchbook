#!/usr/bin/env racket

#lang racket

(require net/http-client
         xml
         xml/path)

(define HOST "nexus.a.fsglobal.net")
(define COLUMN-WIDTH 40)

(define APPROVED-REPO "approved")
(define PAAS-GROUP "org.familysearch.paas")

(struct artifact (repo group id))

(define ARTIFACTS
  (list (artifact APPROVED-REPO PAAS-GROUP "paas-sps-context")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-common")
        (artifact APPROVED-REPO PAAS-GROUP "paas-aws-common")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-rds-common")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-sas-utility")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-common-test")
        (artifact APPROVED-REPO PAAS-GROUP "paas-common-test")
        (artifact APPROVED-REPO PAAS-GROUP "paas-s3-utils")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-artifact-manager")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-config")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sps-launcher")
        (artifact APPROVED-REPO PAAS-GROUP "paas-sysps-context")
        (artifact APPROVED-REPO PAAS-GROUP "paas-github-facade")
        (artifact APPROVED-REPO PAAS-GROUP "github-java-sdk")
        (artifact "thirdparty" "com.amazonaws" "aws-java-sdk-flow-build-tools")
        (artifact "central" "com.amazonaws" "aws-java-sdk")))

(define (build-request-path repository group artifact version)
  (string-append "/service/local/artifact/maven?r=" repository "&g=" group "&a=" artifact "&v=" version))

(define (execute-request path)
  (let-values ([(status-code header in-port) (http-sendrecv HOST path)])
    (xml->xexpr (document-element (read-xml in-port)))))

(define (fetch-latest-artifact-version artifact)
  (let* ([path (build-request-path (artifact-repo artifact) (artifact-group artifact) (artifact-id artifact) "RELEASE")]
         [response (execute-request path)])
    (or (se-path* '(project version) response)
        (se-path* '(project parent version) response))))

(define (build-format-str a)
  (string-append "~a" (make-string (- COLUMN-WIDTH (string-length (artifact-id a))) #\space) "~a~n"))

(define (show-latest-version-for-artifacts artifacts)
  (for ([a (sort artifacts (lambda (a b) (string<? (artifact-group a) (artifact-id b))))])
    (let ([format-str (build-format-str a)])
      (printf format-str (artifact-id a) (fetch-latest-artifact-version a)))))

(show-latest-version-for-artifacts ARTIFACTS)
