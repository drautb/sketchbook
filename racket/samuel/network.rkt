#lang racket

(require "defines.rkt")

(provide (all-defined-out))

(struct packet (timestamp data))

(define received-bytes (make-bytes 1400))

(define (my-hostname)
  (string-trim (with-output-to-string (λ () (system "hostname")))))

(define (send-packet socket target-host target-port data)
  (udp-send-to* socket target-host target-port
                (string->bytes/utf-8 (format "~a" (packet (current-milliseconds) data)))))

(define (receive-packet socket)
  (let-values ([(n-bytes-received host port) (udp-receive!* socket received-bytes)])
    (if n-bytes-received
        (read (open-input-string (bytes->string/utf-8 received-bytes #f 0 n-bytes-received)))
        #f)))
