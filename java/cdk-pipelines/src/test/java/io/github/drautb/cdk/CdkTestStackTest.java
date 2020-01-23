package io.github.drautb.cdk;

import software.amazon.awscdk.core.App;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.junit.Test;
import org.hamcrest.CoreMatchers;

import static org.junit.Assert.assertThat;

public class CdkTestStackTest {

  private final static ObjectMapper JSON =
      new ObjectMapper().configure(SerializationFeature.INDENT_OUTPUT, true);

  @Test
  public void testStack() {
    App app = new App();
    CdkTestStack stack = new CdkTestStack(app, "test");

    JsonNode actual = JSON.valueToTree(app.synth().getStackArtifact(stack.getArtifactId()).getTemplate());
    assertThat(actual.toString(), CoreMatchers.containsString("AWS"));
  }

}
