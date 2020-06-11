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


# Takes a .stuff object as input, and produces a sequence of token objects.
def stuff_to_tokens(f): f |
  if .regions == null then
    .pages[].regions[].lines[].tokens[] else
    .regions[].lines[].tokens[] end;


# Input: .stuff object
# Output: Token sequences where two date tokens are separated by 1-3 unlabeled tokens.
def extract_date_separating_tokens(f): f |
  # Convert stuff to tokens
  [stuff_to_tokens(.)]

  | foreach .[] as $token ({
      in_sequence: false,
      tokens: []
    };

    if ($token.type != null) and
       ($token.type | contains("DATE")) and
       ($token.position == "E" or $token.position == "U") then
      {
        in_sequence: true,
        tokens: [$token]
      }
    else
      if .in_sequence and
         ($token.type != null) and
         ($token.type | contains("DATE")) and
         ($token.position == "B" or $token.position == "U") then
        {
          in_sequence: false,
          tokens: (.tokens + [$token])
        }
      else
        if .in_sequence then
          {
            in_sequence: true,
            tokens: (.tokens + [$token])
          }
        else
          {
            in_sequence: false,
            tokens: []
          }
        end
      end
    end;

    if .in_sequence == false and
       .tokens != [] and
       (.tokens | length) <= 7 then   # 2 tokens for the caps, 5 for separators.
      {
        file: input_filename,
        tokens: .tokens
      }
    else
      empty
    end);


def summarize_date_separating_tokens(f): f |
  {
    file: .file,
    start: (.tokens[0] | .type),
    end: (.tokens[-1:][0] | .type),
    separators: (.tokens[1:-1] | [.[] | .text])
  };
