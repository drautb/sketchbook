#lang racket

(require racket/draw
         "../defines.rkt"
         "../draw.rkt"
         "../state-machine.rkt"
         "singleplayer.rkt"
         "host-multiplayer.rkt"
         "join-multiplayer.rkt")

(provide (all-defined-out))

;; Game state for menu.
(define menu
  (new (class* object% (game-state-interface<%>) (super-new)
         (define/private (exit game)
                         (set-game-should-quit?! game #t))
         (define/public (on-enter) (void))
         (define/public (on-tick game) (void))
         (define/public (on-exit) (void))
         (define/public (on-char game event)
                        (let ([key-code (send event get-key-code)])
                          (cond [(eq? key-code 'escape) (exit game)]
                                [else (void)])))
         (define/public (on-mouse game event)
                        (define-values (x y) (values (send event get-x) (send event get-y)))
                        (when (send event button-down? 'left)
                          (cond [(> y QUIT-Y) (exit game)]
                                [(> y JOIN-MULTIPLAYER-Y)
                                 (set-game-score! game 0) (send (game-state-machine game) push join-multiplayer)]
                                [(> y HOST-MULTIPLAYER-Y)
                                 (set-game-score! game 0) (send (game-state-machine game) push host-multiplayer)]
                                [(> y START-SINGLEPLAYER-Y)
                                 (set-game-score! game 0) (send (game-state-machine game) push singleplayer)]
                                [else (void)])))
         (define/public (on-draw game canvas dc)
                        (send dc set-clipping-rect 0 0 (send canvas get-width) (send canvas get-height))
                        (send dc clear)
                        (send dc draw-bitmap BACKGROUND-IMG 0 0)
                        (keep-transform dc
                                        (send dc scale MENU-FONT-SCALE MENU-FONT-SCALE)
                                        (send dc set-text-foreground "yellow")
                                        (send dc draw-text "Start Singleplayer"
                                              (/ MENU-OPTION-X MENU-FONT-SCALE)
                                              (/ START-SINGLEPLAYER-Y MENU-FONT-SCALE))
                                        (send dc draw-text "Host Multiplayer"
                                              (/ MENU-OPTION-X MENU-FONT-SCALE)
                                              (/ HOST-MULTIPLAYER-Y MENU-FONT-SCALE))
                                        (send dc draw-text "Join Multiplayer"
                                              (/ MENU-OPTION-X MENU-FONT-SCALE)
                                              (/ JOIN-MULTIPLAYER-Y MENU-FONT-SCALE))
                                        (send dc draw-text "Quit"
                                              (/ MENU-OPTION-X MENU-FONT-SCALE)
                                              (/ QUIT-Y MENU-FONT-SCALE)))))))

