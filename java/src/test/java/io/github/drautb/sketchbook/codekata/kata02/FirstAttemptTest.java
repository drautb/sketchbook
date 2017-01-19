package io.github.drautb.sketchbook;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import static org.testng.Assert.*;

public class FirstAttemptTest {

  private FirstAttempt chopper;

  @BeforeMethod
  public void setup() {
    chopper = new FirstAttempt();
  }

  @Test
  public void itShouldReturnTheRightIndices() {
    assertEquals(chopper.chop(0, new int[]{}), -1);
    assertEquals(chopper.chop(0, new int[]{0}), 0);
    assertEquals(chopper.chop(0, new int[]{0, 1}), 0);
    assertEquals(chopper.chop(1, new int[]{0, 1}), 1);
    assertEquals(chopper.chop(2, new int[]{1, 2, 3}), 1);
    assertEquals(chopper.chop(20, new int[]{10, 20, 30, 40, 50, 60, 70, 80, 90}), 1);

    assertEquals(chopper.chop(1, new int[]{1, 3, 5}), 0);
    assertEquals(chopper.chop(3, new int[]{1, 3, 5}), 1);
    assertEquals(chopper.chop(5, new int[]{1, 3, 5}), 2);
    assertEquals(chopper.chop(0, new int[]{1, 3, 5}), -1);
    assertEquals(chopper.chop(2, new int[]{1, 3, 5}), -1);
    assertEquals(chopper.chop(4, new int[]{1, 3, 5}), -1);
    assertEquals(chopper.chop(6, new int[]{1, 3, 5}), -1);

    assertEquals(chopper.chop(1, new int[]{1, 3, 5, 7}), 0);
    assertEquals(chopper.chop(3, new int[]{1, 3, 5, 7}), 1);
    assertEquals(chopper.chop(5, new int[]{1, 3, 5, 7}), 2);
    assertEquals(chopper.chop(7, new int[]{1, 3, 5, 7}), 3);
    assertEquals(chopper.chop(0, new int[]{1, 3, 5, 7}), -1);
    assertEquals(chopper.chop(2, new int[]{1, 3, 5, 7}), -1);
    assertEquals(chopper.chop(4, new int[]{1, 3, 5, 7}), -1);
    assertEquals(chopper.chop(6, new int[]{1, 3, 5, 7}), -1);
    assertEquals(chopper.chop(8, new int[]{1, 3, 5, 7}), -1);
  }

}
