#lang scribble/manual

@title{Chapter 1}

@section{
  Below is a sequence of expressions. What is the result printed by the interpreter in response to each expression? Assume that the sequence is to be evaluated in the order in which it is presented.
}

@codeblock{
10
(+ 5 3 4)
(- 9 1)
(/ 6 2)
(+ (* 2 4) (- 4 6))
(define a 3)
(define b (+ a 1))
(+ a b (* a b))
(= a b)
(if (and (> b a) (< b (* a b)))
    b
    a)
(cond ((= a 4) 6)
      ((= b 4) (+ 6 7 a))
      (else 25))
(+ 2 (if (> b a) b a))
(* (cond ((> a b) a)
         ((< a b) b)
         (else -1))
   (+ a 1))
}

The resulting output will be:

@codeblock{
10
12
8
3
6
-
-
19
#f
4
16
6
16
}

@section{
  Translate the following expression into prefix form:
}

@math{
  5 + 4 + (2 − (3 − (6 + 4 / 5))) / 3(6 − 2)(2 − 7)
}

In prefix form:

@codeblock{
  (/ (+ 5 4 (- 2 (- 3 (+ 6 (/ 4 5)))))
     (* 3 (- 6 2) (- 2 7)))
}

@section{
  Define a procedure that takes three numbers as arguments and returns the sum of the squares of the two larger numbers. 
}

@codeblock{
  (define (sum-squares-of-two-largest x y z)
    (define (square x)
      (* x x))
    (define (sum x y)
      (+ x y))
    (cond )
}