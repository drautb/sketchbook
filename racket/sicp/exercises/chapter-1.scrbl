#lang scribble/manual

@(require scribble/eval
          (for-label racket))

@title{
  Chapter 1
}

@bold{
  @larger{[1.1]} Below is a sequence of expressions. What is the result printed by the
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
  @larger{[1.2]} Translate the following expression into prefix form:
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
  @larger{[1.3]} Define a procedure that takes three numbers as arguments and returns the sum
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
  @larger{[1.4]} Observe that our model of evaluation allows for combinations whose operators
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
  @larger{[1.5]} Ben Bitdiddle has invented a test to determine whether the interpreter he is
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

@bold{
  @larger{[1.6]} Alyssa P. Hacker doesn’t see why if needs to be provided as a
  special form. “Why can’t I just define it as an ordinary procedure in terms of
  cond?” she asks. Alyssa’s friend Eva Lu Ator claims this can indeed be done,
  and she defines a new version of if:
}

@racketblock[
  (define (new-if predicate
                  then-clause
                  else-clause)
    (cond (predicate then-clause)
          (else else-clause)))
]

@bold{
  Eva demonstrates the program for Alyssa:
}

@interaction[
  (define (new-if predicate
                  then-clause
                  else-clause)
    (cond (predicate then-clause)
          (else else-clause)))
  (new-if (= 2 3) 0 5)
  (new-if (= 1 1) 0 5)
]

@bold{
  Delighted, Alyssa uses new-if to rewrite the square-root program:
}

@racketblock[
  (define (sqrt-iter guess x)
    (new-if (good-enough? guess x)
            guess
            (sqrt-iter (improve guess x) x)))
]

@bold{
  What happens when Alyssa attempts to use this to compute square roots?
  Explain.
}

The procedure will enter an infinite loop. @code{new-if} has a similar problem
as applicative-order evaluation, in that it evaluates both @code{then-clause}
and @code{else-clause} when the procedure is called, even though the @code{cond}
expression would only evaluate one. Since @code{sqrt-iter} is recursive, it
causes an infinite loop.

@bold{
  @larger{[1.7]} The good-enough? test used in computing square roots will not be
  very effective for finding the square roots of very small numbers. Also, in
  real computers, arithmetic operations are almost always performed with limited
  precision. This makes our test inadequate for very large numbers. Explain
  these statements, with examples showing how the test fails for small and large
  numbers. An alternative strategy for implementing good-enough? is to watch how
  guess changes from one iteration to the next and to stop when the change is a
  very small fraction of the guess. Design a square-root procedure that uses
  this kind of end test. Does this work better for small and large numbers?
}

