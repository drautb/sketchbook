#lang racket

(define SUFFIX "surefire-reports/index.html")
(define OUTPUT-FILE "/Users/drautb/GitHub/fs-eng/test-reports.html")

(define (locate-test-reports start-dir)
  (for/list ([f (in-directory start-dir)]
             #:when (equal? (substring (path->string f) 
                                       (- (string-length (path->string f)) 
                                          (string-length SUFFIX)))
                            SUFFIX))
    (path->string f)))

(define (generate-report-html report-files)
  (string-join 
    (append (list "<ul>")
            (for/list ([r report-files]) 
              (string-append "<li><a href=" r ">" r "</a></li>"))
            (list "</ul>"))))

(let ([html (generate-report-html (locate-test-reports "/Users/drautb/GitHub/fs-eng"))]
      [output-file (open-output-file OUTPUT-FILE #:exists 'replace)])
  (write html output-file))


