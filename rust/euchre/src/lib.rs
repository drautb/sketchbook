pub mod card;

use std::io;
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

    pub fn pick(&self) {
        if self.game_state != GameState::PickOrPass {
            panic!("pick called when game state was {:?}", self.game_state);
        }


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
