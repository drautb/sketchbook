package io.github.drautb.cfnrules;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author drautb
 */
public class TemplateValidatorTest {

  private static final ObjectMapper MAPPER = new ObjectMapper(new YAMLFactory());

  private TemplateValidator validator;

  @Before
  public void setup() throws Exception {
    validator = new TemplateValidator("redis-rules.yaml");
  }

  @Test
  public void executeTestCases() throws Exception {
    File testCaseFile = new File(ClassLoader.getSystemResource("redis-test-cases.yaml").toURI());
    List<TestCase> testCases = MAPPER.readValue(testCaseFile, new TypeReference<List<TestCase>>() {});

    for (int i = 0; i < testCases.size(); i++) {
      TestCase tc = testCases.get(i);

      List<String> actualErrors = validator.check(tc.template);
      assertThat(actualErrors).isEqualTo(tc.errors);

      System.out.println("TEST " + (i + 1) + " PASSED: " + tc.description);
    }
  }

}
