package io.github.drautb.sketchbook;

import org.testng.annotations.Test;
import org.testng.Assert;

public class AdderTest {

  @Test
  public void itShouldAddRight() {
    Adder adder = new Adder();

    int actual = adder.add(1, 1);

    Assert.assertEquals(2, actual);
  }


}
