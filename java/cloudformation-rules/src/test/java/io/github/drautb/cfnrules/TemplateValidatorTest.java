package io.github.drautb.cfnrules;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author drautb
 */
public class TemplateValidatorTest {

  private static final Yaml YAML = new Yaml(new CloudFormationConstructor());

  private TemplateValidator validator;

  @Before
  public void setup() throws Exception {
    validator = new TemplateValidator("redis-rules.yaml");
  }

  @Test
  @SuppressWarnings("unchecked")
  public void executeTestCases() {
    InputStream testCaseStream = ClassLoader.getSystemResourceAsStream("redis-test-cases.yaml");
    List<Map<Object, Object>> testCasesRaw = (List<Map<Object, Object>>) YAML.load(testCaseStream);
    List<TestCase> testCases = new ObjectMapper().convertValue(testCasesRaw, new TypeReference<List<TestCase>>() {});

    for (int i = 0; i < testCases.size(); i++) {
      TestCase tc = testCases.get(i);

      List<String> actualErrors = validator.check(tc.template);
      assertThat(actualErrors).isEqualTo(tc.errors);

      System.out.println("TEST " + (i + 1) + " PASSED: " + tc.description);
    }
  }

}
