package io.github.drautb.cfnrules;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.TestFactory;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author roskelleycj
 */
@SuppressWarnings("unchecked")
public class TemplateValidatorTest {

  @TestFactory
  Stream<DynamicTest> dynamicTestsFromStreamInJava8() throws Exception {

    Yaml yaml = new Yaml(new CloudFormationConstructor());
    TemplateValidator validator = new TemplateValidator("redis-rules.yaml");
    InputStream testCaseStream = ClassLoader.getSystemResourceAsStream("redis-test-cases.yaml");
    List<Map<Object, Object>> testCasesRaw = (List<Map<Object, Object>>) yaml.load(testCaseStream);
    List<TestCase> testCases = new ObjectMapper().convertValue(testCasesRaw, new TypeReference<List<TestCase>>() {});

    return testCases.stream().map(testCase -> DynamicTest.dynamicTest(testCase.description,
        () -> {
      List<String> actualErrors = validator.check(testCase.template);
      assertThat(actualErrors).isEqualTo(testCase.errors);
    }));

  }
}
