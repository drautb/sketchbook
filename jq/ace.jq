# Takes a .stuff object as input, and produces a sequence of entity
# objects with their original/text strings and entity type.
def stuff_to_entities(f): f |
  # Create a flat list of tokens with newlines inserted as
  # the post character for the final token on each line.
  [ (if .regions == null then
      .pages[].regions[].lines[] else
      .regions[].lines[] end) | .tokens[:-1] + [.tokens[-1] | .post = "\n"]] | flatten

  # Stitch tokens together. Tokens without a position field are
  # naturally dropped, unless they fall between tokens with a
  # begin or end position.
  | foreach .[] as $token ([[], []];
      ($token.post // " ") as $post |
      if $token.position == "U" or $token.position == "B" then
        [
          [$token.text + $post],
          [$token.orig + $post]
        ]
      else
        [
          .[0] + [$token.text + $post],
          .[1] + [$token.orig + $post]
        ]
      end;
      if $token.position == "U" or $token.position == "E" then
        {
          text: .[0],
          orig: [.[1] | .[] | select(. != null)],
          type: $token.type
        }
      else
        empty
      end)

  # Concatenate text arrays into strings.
  | {
    text: .text | join("") | ltrimstr(" ") | rtrimstr(" "),
    orig: .orig | join("") | ltrimstr(" ") | rtrimstr(" "),
    type
  };
