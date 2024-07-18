pub mod card;

use std::io;
use std::mem;
use rand::Rng;

use card::{Card, Suit, Value};



// Game sequence:
// Play rounds until one team reaches 10 points
//  Round:
/*
    select player to deal
    shuffle and deal 5 cards to each player
    starting left of dealer, each player can say pick it up or pass
    if back to dealer, flip it over and repeat but choosing a suit
    dealer must decide eventually.
    Outcome: a trump suit is selected
        Play round until score limit is reached
*/

/*
Game state:
* Dealer
* Team points
*/

/*
Round State:
* Player hands
* Tricks won
*/

/*
less interested in remaking the whole game, more interested in running sims to see likelihood of victory, or stats about who may have what cards
*/

#[derive(Debug, PartialEq, Eq)]
enum GameState {
    PickOrPass,
    ChooseOrPass,
    Play
}

#[derive(Debug)]
struct Game {
    dealer: u8,
    turn: u8,
    trump: Suit,
    scores: Vec<u8>,
    players: Vec<Player>,
    leftovers: Vec<Card>,
    game_state: GameState,
}

impl Game {
    pub fn new() -> Self {
        Game {
            dealer: 0,
            turn: 1,
            trump: Suit::Clubs,
            scores: vec![0, 0],
            players: vec![
                Player::new(),
                Player::new(),
                Player::new(),
                Player::new(),
            ],
            leftovers: vec![],
            game_state: GameState::PickOrPass
        }
    }

    pub fn deal(&mut self) {
        let mut deck = self.generate_deck();
        let mut shuffled = vec![];
        while deck.len() > 0 {
            let card = deck.remove(rand::thread_rng().gen_range(0..deck.len()));
            shuffled.push(card);
        }

        for p in 0..self.players.len() {
            self.players[p].hand.clear();
        }

        self.players[1].hand.extend_from_slice(&shuffled[0..3]);
        self.players[2].hand.extend_from_slice(&shuffled[3..5]);
        self.players[3].hand.extend_from_slice(&shuffled[5..8]);
        self.players[0].hand.extend_from_slice(&shuffled[8..10]);

        self.players[1].hand.extend_from_slice(&shuffled[10..12]);
        self.players[2].hand.extend_from_slice(&shuffled[12..15]);
        self.players[3].hand.extend_from_slice(&shuffled[15..17]);
        self.players[0].hand.extend_from_slice(&shuffled[17..20]);

        self.leftovers.clear();
        self.leftovers.extend_from_slice(&shuffled[20..24]);

        self.turn = next_player(self.dealer);
    }

    fn generate_deck(&self) -> Vec<Card> {
        return vec![
            Card(Value::Ace, Suit::Clubs),
            Card(Value::King, Suit::Clubs),
            Card(Value::Queen, Suit::Clubs),
            Card(Value::Jack, Suit::Clubs),
            Card(Value::Ten, Suit::Clubs),
            Card(Value::Nine, Suit::Clubs),

            Card(Value::Ace, Suit::Diamonds),
            Card(Value::King, Suit::Diamonds),
            Card(Value::Queen, Suit::Diamonds),
            Card(Value::Jack, Suit::Diamonds),
            Card(Value::Ten, Suit::Diamonds),
            Card(Value::Nine, Suit::Diamonds),

            Card(Value::Ace, Suit::Hearts),
            Card(Value::King, Suit::Hearts),
            Card(Value::Queen, Suit::Hearts),
            Card(Value::Jack, Suit::Hearts),
            Card(Value::Ten, Suit::Hearts),
            Card(Value::Nine, Suit::Hearts),

            Card(Value::Ace, Suit::Spades),
            Card(Value::King, Suit::Spades),
            Card(Value::Queen, Suit::Spades),
            Card(Value::Jack, Suit::Spades),
            Card(Value::Ten, Suit::Spades),
            Card(Value::Nine, Suit::Spades),
        ];
    }

    /**
     * discard - the dealer's card to discard.
     */
    pub fn pick(&mut self, discard: Card) {
        if self.game_state != GameState::PickOrPass {
            panic!("pick called when game state was {:?}", self.game_state);
        }

        let dealer = &mut self.players[self.dealer as usize];
        for card in dealer.hand.iter_mut() {
            if *card == discard {
                self.trump = self.leftovers[0].1;
                mem::swap(card, &mut self.leftovers[0]);
                self.game_state = GameState::Play;
                self.turn = next_player(self.dealer);
                return
            }
        }

        panic!("pick called with invalid discard {:?}, dealer's hand: {:?}", discard, dealer.hand);
    }

    pub fn pass(&mut self) {
        if self.game_state != GameState::PickOrPass || self.game_state != GameState::ChooseOrPass {
            panic!("pass called when game state was {:?}", self.game_state);
        }

        if self.turn == self.dealer {
            if self.game_state == GameState::PickOrPass {
                self.game_state = GameState::ChooseOrPass;
            } else {
                panic!("Dealer cannot pass!");
            }
        }

        self.turn = next_player(self.turn);
    }

    pub fn choose(&mut self, trump: Suit) {
        if self.game_state != GameState::ChooseOrPass {
            panic!("choose called when game state was {:?}", self.game_state);
        }

        self.trump = trump;
        self.turn = next_player(self.dealer);
        self.game_state = GameState::Play;
    }j
}

fn next_player(current_player: u8) -> u8 {
    if current_player == 3 {
        0
    } else {
        current_player + 1
    }
}

#[derive(Debug)]
struct Player {
    hand: Vec<Card>,
    tricks_won: u8,
}

impl Player {
    pub fn new() -> Self {
        Player {
            hand: vec![],
            tricks_won: 0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test() {
        let mut g = Game::new();
        g.deal();
        println!("{:?}", g);
    }
}
