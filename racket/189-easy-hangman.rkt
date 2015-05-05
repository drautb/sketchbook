#lang racket

(require data/gvector)

(define gallows-template 
  (string-append "   _____\n"
                 "  |    |\n"
                 "  |    1\n"
                 "  |   324\n"
                 "  |    2\n"
                 "  |   5 6\n"
                 "__|_________\n"))

(define transforms
  (make-hash '(("1" . "O")
               ("2" . "|")
               ("3" . "/")
               ("4" . "\\")
               ("5" . "/")
               ("6" . "\\"))))

(define (replace-numbers-in-gallows template missed)
  (cond
    [(= missed 0) template]
    [else (replace-numbers-in-gallows 
           (string-replace template 
                           (number->string missed)
                           (hash-ref transforms (number->string missed))) 
           (- missed 1))]))

(define (show-hangman missed-guesses)
  (let ([gallows (replace-numbers-in-gallows gallows-template missed-guesses)])
    (display (regexp-replace* #rx"(?m:[0-9])" gallows " "))))

(define (get-difficulty)
  (begin
    (display "Select your difficulty: easy, medium, hard.\n")
    (let ([input (read)])
      (cond [(member input '(easy medium hard)) input]
            [else (begin
                    (fprintf (current-output-port)
                             "'~a' is not valid input.~n" 
                             input)
                    (get-difficulty))]))))

(define (load-wordfile)
  (let ([easy-wordlist (make-gvector #:capacity 200000)]
        [medium-wordlist (make-gvector #:capacity 200000)]
        [hard-wordlist (make-gvector #:capacity 200000)])
    (define (read-next-line-iter file)
      (let* ([line (read-line file)])
        (unless (eof-object? line)
          (let ([line (string-upcase (string-replace line "'" ""))]
                [len (string-length line)])
            (cond [(> len 7) (gvector-add! easy-wordlist line)]
                  [(> len 5) (gvector-add! medium-wordlist line)]
                  [(> len 3) (gvector-add! hard-wordlist line)])
            (read-next-line-iter file)))))
    (call-with-input-file "/Users/drautb/Downloads/wordlist.txt" read-next-line-iter)
    (values easy-wordlist medium-wordlist hard-wordlist)))

(define-values (easy-list medium-list hard-list) (load-wordfile))

(define (select-word difficulty)
  (let ([wordlist (cond [(eq? difficulty 'easy) easy-list]
                        [(eq? difficulty 'medium) medium-list]
                        [else hard-list])])
    (gvector-ref wordlist (random (gvector-count wordlist)))))

(define (show-word word guessed)
  (for ([c word])
    (cond [(member c guessed) (printf " ~a " c)]
          [else (display " _ ")])))

(define (count-failed-guesses word guessed)
  (cond [(empty? guessed) 0]
        [(member (car guessed) (string->list word)) (count-failed-guesses word (cdr guessed))]
        [else (+ 1 (count-failed-guesses word (cdr guessed)))]))

(define (show-hud word guessed)
  (show-hangman (count-failed-guesses word guessed)) (newline)
  (show-word word guessed) (newline) (newline))

(define (get-guess guessed)
  (display "Guess a letter.\n")
  (let ([guess (char-upcase (string-ref (symbol->string (read)) 0))])
    (cond [(member guess guessed)
           (begin (display "You already guessed that letter!\n")
                  (get-guess guessed))]
          [(char-alphabetic? guess) guess]
          [else (begin (display "That isn't a valid guess!\n")
                       (get-guess guessed))])))

(define (game-won word guessed)
  (cond [(zero? (string-length word)) #t]
        [(member (string-ref word 0) guessed) (game-won (substring word 1) guessed)]
        [else #f]))

(define (game-lost word guessed)
  (>= (count-failed-guesses word guessed) 6))

(define (guess-cycle word guessed)
  (show-hud word guessed)
  (cond [(game-lost word guessed) (printf "You lost! The word was: ~a." word)]
        [(game-won word guessed) (display "Congratulations!!")]
        [else (guess-cycle word (cons (get-guess guessed) guessed))]))

(define (start-game)
  (let* ([difficulty (get-difficulty)]
         [word (select-word difficulty)]
         [guessed '()])
    (guess-cycle word guessed)))
    
    
    