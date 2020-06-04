#!/usr/bin/env gawk -f

BEGIN {
  print "digraph {"
  print "  node [shape=record]"
}
{
  if (!/<RELEX /) {
    next
  }

  if (match($0, /TYPE="([^"]*)".*_STTOKEN="([^"]*)".*_ENDTOKEN="([^"]*)"/, groups)) {
    print "  \"" groups[2] "\" -> \"" groups[3] "\" [label=\"" groups[1] "\"]"
  }
}
END {
  print "}"
}
