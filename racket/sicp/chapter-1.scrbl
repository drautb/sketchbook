#lang scribble/manual

@(require scribble/eval
          (for-label racket))

@title{
  Chapter 1
}

@bold{
  @larger{Exercise 1.1} Below is a sequence of expressions. What is the result printed by the
  interpreter in response to each expression? Assume that the sequence is to be
  evaluated in the order in which it is presented.
}

@racketblock[
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
]

The resulting output will be:

@racketblock[
10
12
8
3
6
19
#f
4
16
6
16
]

@bold{
  Translate the following expression into prefix form:
}

@math{
  5 + 4 + (2 − (3 − (6 + 4 / 5))) / 3(6 − 2)(2 − 7)
}

In prefix form:

@racketblock[
  (/ (+ 5 4 (- 2 (- 3 (+ 6 (/ 4 5)))))
     (* 3 (- 6 2) (- 2 7)))
]

@bold{
  Define a procedure that takes three numbers as arguments and returns the sum
  of the squares of the two larger numbers.
}

@racketblock[
  (define (sum-squares-of-two-largest x y z)
    (define (square x)
      (* x x))
    (define (sum x y)
      (+ x y))
    (cond [(and (> x z) (> y z))
           (sum (square x) (square y))]
          [(and (> x y) (> z y))
           (sum (square x) (square z))]
          [else (sum (square y) (square z))]))
]

@bold{
  Observe that our model of evaluation allows for combinations whose operators
  are compound expressions. Use this observation to describe the behavior of the
  following procedure:
}

@racketblock[
  (define (a-plus-abs-b a b)
    ((if (> b 0) + -) a b))
]

The procedure determines which procedure to apply to @code{a} and @code{b}
dynamically. if @code{(> b 0)} evaluates to true, then @code{(+ a b)} is
evaluated. Otherwise @code{(- a b)} is evaluated.

@bold{
  Ben Bitdiddle has invented a test to determine whether the interpreter he is
  faced with is using applicative-order evaluation or normal-order evaluation.
  He defines the following two procedures:
}

@racketblock[
  (define (p) (p))

  (define (test x y)
    (if (= x 0)
        0
        y))
]

@bold{
  Then he evaluates the expression
}

@racketblock[
  (test 0 (p))
]

@bold{
  What behavior will Ben observe with an interpreter that uses applicative-order
  evaluation? What behavior will he observe with an interpreter that uses
  normal-order evaluation? Explain your answer. (Assume that the evaluation rule
  for the special form if is the same whether the interpreter is using normal or
  applicative order: The predicate expression is evaluated first, and the result
  determines whether to evaluate the consequent or the alternative expression.)
}

In an interpreter that uses applicative-order evaluation, the arguments to
@code{test} will be evaluated first, resulting in @code{0} and an infinite-loop,
respectively. Thus, if the interpreter uses applicative-order evaluation, the
computation will never complete.

In an interpreter that uses normal-order evaluation, the arguments will be
replaced in the body of the procedure as they are, and then only evaluated if
they're needed. So @code{(test 0 (p))} will be replaced with:

@racketblock[
  (if (= 0 0)
      0
      (p))
]

Because the predicate evaluates to @code{#t} here, @code{0} is returned, and
@code{(p)} is never evaluated. Thus, in an interpreter that users normal-order
evaluation, the output will be @code{0}.
