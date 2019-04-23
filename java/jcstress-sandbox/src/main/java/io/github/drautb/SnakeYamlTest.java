package io.github.drautb;

import org.openjdk.jcstress.annotations.*;
import org.openjdk.jcstress.infra.results.IntResult1;
import org.yaml.snakeyaml.Yaml;

/**
 * @author drautb
 */
//@JCStressTest
@Outcome(id = "0", expect = Expect.ACCEPTABLE, desc = "Default outcome, no errors.")
@State
public class SnakeYamlTest {

  private static final int ITERATIONS = 1000;
  private static final String YAML_STR = "test-map:\n  key-one: value-one\n  key-two: 5\n";

  private static final Yaml yaml = new Yaml();

  @Actor
  public void actor1(IntResult1 r) {
    parseYaml(r);
  }

  @Actor
  public void actor2(IntResult1 r) {
    parseYaml(r);
  }

  private void parseYaml(IntResult1 r) {
    for (int n=0; n<ITERATIONS; n++) {
      try {
        yaml.load(YAML_STR);
      }
      catch (Exception e) {
        r.r1++;
      }
    }
  }

}
