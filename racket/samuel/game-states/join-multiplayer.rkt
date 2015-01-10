#lang racket

(require racket/draw
         racket/gui
         "../defines.rkt"
         "../draw.rkt"
         "../network.rkt"
         "../state-machine.rkt")

(provide (all-defined-out))

;; Game state for a joined multplayer mode
;; This is a client, it just sends cmds to the host, and updates its world.
(define join-multiplayer
  (new (class* object% (game-state-interface<%>) (super-new)
         (define listening-socket (udp-open-socket))
         (define sending-socket (udp-open-socket))
         (define server-host null)
         (define current-world null)
         (define recvd-msg (make-bytes 4096))
         (define/public (on-enter)
                        (unless (udp-bound? listening-socket) (udp-bind! listening-socket #f CLIENT-PORT))
                        (let ([input(get-text-from-user "Join Game" "Enter the IP or Hostname to connect to" #f "localhost")])
                          (set! server-host input)
                          (send-packet sending-socket server-host HOST-PORT (cmd (my-hostname) #f #f))))
         (define/public (on-tick game)
                        (unless (or (null? current-world)
                                    (sam-is-hit? (world-sam current-world)
                                                 (world-arrows current-world)))
                          (tick-world current-world (game-time-delta game)))
                        (let-values ([(recvd host port) (udp-receive!* listening-socket recvd-msg)])
                          (when recvd
                            ; (displayln (string-append "CLIENT RECD: " (bytes->string/utf-8 recvd-msg #f 0 recvd)))
                            (let ([world (read (open-input-string (bytes->string/utf-8 recvd-msg #f 0 recvd)))])
                              (set! current-world world)))))
         (define/public (on-exit) (void))
         (define/public (on-char game event)
                        (define (send-move nephite new-x-vel)
                          (set-sprite-x-vel! nephite new-x-vel)
                          (unless (null? server-host)
                            (send-packet sending-socket server-host HOST-PORT (cmd #f new-x-vel #f))))
                        (define (send-fire-arrow)
                          (unless (null? server-host)
                            (send-packet sending-socket server-host HOST-PORT (cmd #f #f #t))))
                        (unless (null? current-world)
                          (let ([key-code (send event get-key-code)]
                                [nephite (first (world-nephites current-world))])
                            (cond [(eq? key-code 'escape) (send (game-state-machine game) pop)]
                                  [(eq? key-code 'left) (unless (= (sprite-x-vel nephite) (- NEPHITE-X-VEL))
                                                          (send-move nephite (- NEPHITE-X-VEL)))]
                                  [(eq? key-code 'right) (unless (= (sprite-x-vel nephite) NEPHITE-X-VEL)
                                                           (send-move nephite NEPHITE-X-VEL))]
                                  [(eq? key-code #\space) (send-fire-arrow)]
                                  [(and (eq? key-code 'release)
                                        (or (eq? (send event get-key-release-code) 'left)
                                            (eq? (send event get-key-release-code) 'right)))
                                   (send-move nephite 0)]
                                  [else (void)]))))
         (define/public (on-mouse game event) (void))
         (define/public (on-draw game canvas dc)
                        (unless (null? current-world)
                          (draw-world dc current-world))))))

