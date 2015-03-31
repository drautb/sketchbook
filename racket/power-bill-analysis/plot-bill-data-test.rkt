#lang racket

(require rackunit
         "plot-bill-data.rkt")

(define test-bill #hasheq((usage . 583)
                           (billDate
                            .
                            #hasheq((day . 26) (month . 1) (year . 2015)))
                           (startDate
                            .
                            #hasheq((day . 18) (month . 12) (year . 2014)))
                           (endDate
                            .
                            #hasheq((day . 19) (month . 1) (year . 2015)))
                           (multiplier . 1)
                           (blocks
                            .
                            #hasheq((|1|
                                     .
                                     #hasheq((usage . 500) (rate . 0.0835)))
                                    (|2|
                                     .
                                     #hasheq((usage . 83) (rate . 0.097)))))
                           (customerService . 6.25)
                           (telecomDebt . 5.35)
                           (municipalUse . 3.68)
                           (stateSalesTax . 2.49)
                           (totalAmount . 69.67)
                           (residentialTransportationFee . 2.1)))


;; date-hash-to-date
(test-case
  "date-hash-to-date to should create a correct date from the hash"
  (check-equal? (date-hash-to-date (hash-ref test-bill 'startDate))
                (date 0 0 0 18 12 2014 0 0 0 0)))


;; end-date
(test-case
  "end-date should return a proper date representing the end date of a bill"
  (check-equal? (end-date test-bill)
                (date 0 0 0 19 1 2015 0 0 0 0)))


;; extraction functions
(check-equal? (total-amount test-bill) 69.67)
(check-equal? (usage test-bill) 583)
(check-equal? (customer-service test-bill) 6.25)
(check-equal? (telecom-debt test-bill) 5.35)
(check-equal? (municipal-use test-bill) 3.68)
(check-equal? (state-sales-tax test-bill) 2.49)
(check-equal? (residential-transportation-fee test-bill) 2.1)

;; generate-line-data
(test-case
  "generate-line-data should return an appropriate point sequence"
  (check-equal? (generate-line-data (list test-bill) total-amount)
                (list '(1421650800 69.67))))
