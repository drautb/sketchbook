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
# Arguments: String that must be contained in the type of the target token.
#            Number of trailing tokens to collect.
# Output: Token sequences of specified lendth that follow tokens of the given type.
def extract_trailing_tokens($type_contains; $count):
  [stuff_to_tokens(.)] | . as $tokens

  ## Find indices of E/U tokens containing the type,
  | [indices(.[] |
      select(.type != null and (.type | contains($type_contains)) and
             (.position == "U" or .position == "E")))] | flatten

  ### Project those indices + count from the token list.
  | map($tokens[.:(. + $count + 1)]);


# Input: .stuff object
# Arguments: String that must be contained in the type of the bookend tokens.
# Output: Token sequences where two tokens tokens whose types contain
# $type_contains are separated by 1-$threshold other tokens.
def extract_separating_tokens($type_contains; $threshold):
  # Convert stuff to tokens
  [stuff_to_tokens(.)]

  | foreach .[] as $token ({
      in_sequence: false,
      tokens: []
    };

    if ($token.type != null) and
       ($token.type | contains($type_contains)) and
       ($token.position == "E" or $token.position == "U") then
      {
        in_sequence: true,
        tokens: [$token]
      }
    else
      if .in_sequence and
         ($token.type != null) and
         ($token.type | contains($type_contains)) and
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
       ((.tokens | length) <= ($threshold + 2)) then   # 2 tokens for the caps.
      {
        file: input_filename,
        tokens: .tokens
      }
    else
      empty
    end);


def summarize_separating_tokens(f): f |
  {
    file: .file,
    start: .tokens[0],
    end: .tokens[-1:][0],
    separators: (.tokens[1:-1] | [.[] | .text])
  };
