package io.github.drautb.sketchbook;

import java.util.*;

/**
 * http://codekata.com/kata/kata02-karate-chop/
 *
 * Choices:
 *   -  Static method vs. instantiation.
 *   -  Iterative vs. Recursive.
 *   -  How to detect when you're flipping back and forth between the same
 *      two positions? (The item isn't present, but you keep looking for it
 *      at idx 10 and 11 for example.)
 */
public class FirstAttempt {

  public int chop(int toFind, int[] sortedNumbers) {
    int foundIdx = -1;
    int leftBound = 0, rightBound = sortedNumbers.length;

    List<Integer> visited = new ArrayList<Integer>();

    if (sortedNumbers.length == 0) {
      return foundIdx;
    }

    while (true) {
      int middle = (rightBound - leftBound) / 2;
      if (visited.contains(middle)) {
        break;
      }

      visited.add(middle);

      int found = sortedNumbers[middle];

      if (found == toFind) {
        foundIdx = middle;
        break;
      }

      if (found < toFind) {
        leftBound = middle;
      }
      else if (found > toFind) {
        rightBound = middle;
      }
    }

    return foundIdx;
  }

}

