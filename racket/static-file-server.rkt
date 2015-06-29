#lang racket

(require web-server/servlet
         web-server/servlet-env)

(define (start req)
  (response/xexpr
   `(html (head (title "Static File Server"))
          (body (p "No file here")))))

(serve/servlet start
               #:port 8080
               #:servlet-path "/main"
               #:extra-files-paths (list "/Users/drautb/GitHub/drautb/sketchbook")
               #:command-line? #t)
