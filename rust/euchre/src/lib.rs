pub enum Suit {
    Clubs,
    Diamonds,
    Hearts,
    Spades,
}

pub enum Value {
    Ace = 14,
    King = 13,
    Queen = 12,
    Jack = 11,
    Ten = 10,
    Nine = 9
}

pub struct Card(Value, Suit);

impl Card {
    fn beats(card: &Card,
        other: &Card,
        trump: Suit,
        lead: Suit) -> bool {

        return false
    }
}

pub fn generate_deck() -> Vec<Card> {
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
