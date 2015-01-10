#lang racket

(require racket/draw
         "../defines.rkt"
         "../draw.rkt"
         "../network.rkt"
         "../state-machine.rkt")

(provide (all-defined-out))

;; Game state for a hosted multplayer mode
;; The host acts as the game server, so it ticks everything.
;; It also sends the world state to the client, so it can update its view.
(define host-multiplayer
  (new (class* object% (game-state-interface<%>) (super-new)
         (define listening-socket (udp-open-socket))
         (define sending-socket (udp-open-socket))
         (define client-host null)
         (define current-world null)
         (define last-network-update 0)
         (define recvd-msg (make-bytes 4096))
         (define/public (on-enter)
                        (unless (udp-bound? listening-socket) (udp-bind! listening-socket #f HOST-PORT))
                        (set! current-world (new-world #f)))
         (define/public (on-tick game)
                        (let* ([sam (world-sam current-world)]
                               [delta (game-time-delta game)])
                          (unless (sam-is-hit? sam (world-arrows current-world))
                            (tick-world current-world delta)))
                        (let ([packet (receive-packet listening-socket)])
                          (when packet
                            (let ([cmd (packet-data packet)]
                                  [nephite (first (world-nephites current-world))])
                              (cond [(cmd-join-host cmd) (set! client-host (symbol->string (cmd-join-host cmd)))]
                                    [(cmd-new-x-vel cmd) (set-sprite-x-vel! nephite (cmd-new-x-vel cmd))]
                                    [(cmd-fire-arrow cmd) (fire-arrow current-world nephite)]
                                    [else (void)]))))
                        (unless (or (null? client-host)
                                    (< (- (current-milliseconds) last-network-update) NETWORK-UPDATE-INTERVAL-MS))
                          (set! last-network-update (current-milliseconds))
                          (send-packet sending-socket client-host CLIENT-PORT current-world)))
         (define/public (on-exit) (void))
         (define/public (on-char game event)
                        (let ([key-code (send event get-key-code)]
                              [sam (world-sam current-world)])
                          (cond [(eq? key-code 'escape) (send (game-state-machine game) pop)]
                                [(eq? key-code 'left) (set-sprite-x-vel! sam (- SAM-X-VEL))]
                                [(eq? key-code 'right) (set-sprite-x-vel! sam SAM-X-VEL)]
                                [(eq? key-code 'release)
                                 (when (or (and (eq? (send event get-key-release-code) 'left)
                                                (eq? (sprite-x-vel sam) (- SAM-X-VEL)))
                                           (and (eq? (send event get-key-release-code) 'right)
                                                (eq? (sprite-x-vel sam) SAM-X-VEL)))
                                   (set-sprite-x-vel! sam 0))]
                                [else (void)])))
         (define/public (on-mouse game event) (void))
         (define/public (on-draw game canvas dc)
                        (draw-world dc current-world)))))

