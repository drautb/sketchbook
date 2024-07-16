#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Suit {
    Clubs,
    Diamonds,
    Hearts,
    Spades,
}

impl Suit {
    pub fn complement(&self) -> Suit {
        match self {
            Suit::Clubs => Suit::Spades,
            Suit::Diamonds => Suit::Hearts,
            Suit::Hearts => Suit::Diamonds,
            Suit::Spades => Suit::Clubs
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Value {
    Ace,
    King,
    Queen,
    Jack,
    Ten,
    Nine,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Card(pub Value, pub Suit);

impl Card {
    pub fn beats(&self, other: &Card, ordering: &Vec<Card>) -> bool {
        return self.rank(ordering) < other.rank(ordering);
    }

    pub fn rank(&self, ordering: &Vec<Card>) -> u8 {
        for i in 0..ordering.len() {
            if ordering.get(i) == Some(self) {
                return i as u8;
            }
        }
        return u8::MAX;
    }

    fn can_play(&self, hand: &Vec<Card>, lead: Option<Suit>) -> bool {
        if lead.is_none() {
            return true
        }

        let lead = lead.unwrap();
        if hand.iter().any(|c| c.1 == lead || (c.0 == Value::Jack && c.1 == lead.complement())) {
            return self.1 == lead || (self.0 == Value::Jack && self.1 == lead.complement())
        } else {
            return true
        }
    }
}

pub fn generate_ordering(trump: Suit, lead: Suit) -> Vec<Card> {
    return vec![
        Card(Value::Jack, trump),
        Card(Value::Jack, trump.complement()),
        Card(Value::Ace, trump),
        Card(Value::King, trump),
        Card(Value::Queen, trump),
        Card(Value::Ten, trump),
        Card(Value::Nine, trump),

        Card(Value::Ace, lead),
        Card(Value::King, lead),
        Card(Value::Queen, lead),
        Card(Value::Ten, lead),
        Card(Value::Nine, lead)
    ];
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_card_rankings() {
        let mut ordering = generate_ordering(Suit::Diamonds, Suit::Clubs);
        assert_eq!(Card(Value::Ace, Suit::Clubs).beats(&Card(Value::Jack, Suit::Clubs), &ordering), true);

        ordering = generate_ordering(Suit::Clubs, Suit::Clubs);

        // Right bower
        assert_eq!(Card(Value::Ace, Suit::Clubs).beats(&Card(Value::Jack, Suit::Clubs), &ordering), false);
        assert_eq!(Card(Value::Jack, Suit::Clubs).beats(&Card(Value::Ace, Suit::Clubs), &ordering), true);

        // Left bower
        assert_eq!(Card(Value::Ace, Suit::Clubs).beats(&Card(Value::Jack, Suit::Spades), &ordering), false);
        assert_eq!(Card(Value::Jack, Suit::Spades).beats(&Card(Value::Ace, Suit::Clubs), &ordering), true);

        ordering = generate_ordering(Suit::Clubs, Suit::Diamonds);

        assert_eq!(Card(Value::Ace, Suit::Clubs).beats(&Card(Value::Ace, Suit::Diamonds), &ordering), true);
        assert_eq!(Card(Value::Ace, Suit::Clubs).beats(&Card(Value::Ten, Suit::Clubs), &ordering), true);
        assert_eq!(Card(Value::Ace, Suit::Diamonds).beats(&Card(Value::Ten, Suit::Diamonds), &ordering), true);

        // If two cards aren't either trump or lead, then they don't beat anything, not even each other.
        assert_eq!(Card(Value::Ace, Suit::Hearts).beats(&Card(Value::Ten, Suit::Hearts), &ordering), false);
        assert_eq!(Card(Value::Ten, Suit::Hearts).beats(&Card(Value::Ace, Suit::Hearts), &ordering), false);
    }

    #[test]
    fn test_card_can_play() {
        let ten_hearts = Card(Value::Ten, Suit::Hearts);
        let ten_spades = Card(Value::Ten, Suit::Spades);
        let jack_spades = Card(Value::Jack, Suit::Spades);

        assert_eq!(ten_hearts.can_play(&vec![ten_hearts, jack_spades], None), true);
        assert_eq!(ten_hearts.can_play(&vec![ten_hearts, jack_spades], Some(Suit::Hearts)), true);
        assert_eq!(ten_hearts.can_play(&vec![ten_hearts, jack_spades], Some(Suit::Spades)), false);
        assert_eq!(jack_spades.can_play(&vec![ten_hearts, jack_spades], Some(Suit::Spades)), true);

        assert_eq!(ten_hearts.can_play(&vec![ten_hearts, jack_spades], Some(Suit::Clubs)), false);
        assert_eq!(jack_spades.can_play(&vec![ten_hearts, jack_spades], Some(Suit::Clubs)), true);

        assert_eq!(ten_spades.can_play(&vec![ten_hearts, ten_spades], Some(Suit::Clubs)), true);
        assert_eq!(ten_spades.can_play(&vec![ten_hearts, ten_spades, jack_spades], Some(Suit::Clubs)), false);
    }
}
