#lang racket

(require xml)

(define BLOG-XML "/home/drautb/blog.xml")
(define OUTPUT-DIR "/home/drautb/GitHub/drautfamily.github.io/_src/posts/")

(struct post (title date-posted name tags content))

(define (make-post post-data)
  (define (extract-data post-data type)
    (let ([title-list 
           (first (memf (lambda (piece)
                          (cond [(and (list? piece) (not (empty? piece))
                                      (eq? (first piece) type))
                                 #t]
                                [else #f]))
                        post-data))])
      (cond [(>= (length title-list) 3)
             (third title-list)]
            [else "No Title"])))
  (define (extract-content post-data)
    (cdata-string (extract-data post-data 'content:encoded)))
  (post (extract-data post-data 'title)
        (extract-data post-data 'wp:post_date)
        (extract-data post-data 'wp:post_name)
        (list "Weekly Letters")
        (extract-content post-data)))

(define (generate-post-filename post)
  (let ([date (post-date-posted post)]
        [name (post-name post)])
    (string-append (first (string-split date))
                   "-" name ".md")))

(define (generate-post-body post)
  (let ([date (post-date-posted post)]
        [title (post-title post)]
        [tags (post-tags post)]
        [content (post-content post)])
    (string-append "    Title: " title "\n"
                   "    Date: " (string-replace date " " "T") "\n"
                   "    Tags: " (string-join tags ", ") "\n\n"
                   (substring content 
                              9 
                              (- (string-length content) 3)))))

(define (write-post-to-file post)
  (let ([body (generate-post-body post)]
        [output-filename (string-append OUTPUT-DIR (generate-post-filename post))])
    (display-to-file body output-filename)))

(define (load-wp-data file) 
  (parameterize ([collapse-whitespace #t])
    (xml->xexpr (document-element
                 (read-xml (open-input-file file))))))

(define (is-post? item)
  (member '(wp:post_type () "post")
          item))
  
(define (find-list data type)
  (filter (λ (item)
            (and (list? item)
                 (not (empty? item))
                 (eq? (car item) type)))
          data))
  
(define (locate-post-list data)
  (let ([item-list (find-list 
                    (first (find-list data 'channel))
                    'item)])
    (filter (λ (item)
              (is-post? item))
            item-list)))

(define (convert-blog)
  (let* ([data (load-wp-data BLOG-XML)]
         [posts (locate-post-list data)])
    (for ([post-data posts])
      (let ([post (make-post post-data)])
        (printf "Processing post '~a'~n" (post-title post))
        (write-post-to-file post)))))

(convert-blog)
 


