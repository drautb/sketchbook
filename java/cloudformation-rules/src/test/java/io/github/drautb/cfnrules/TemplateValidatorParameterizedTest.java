/*
 * © 2019 by Intellectual Reserve, Inc. All rights reserved.
 */

package io.github.drautb.cfnrules;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.yaml.snakeyaml.Yaml;

import java.io.InputStream;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author roskelleycj
 */
@RunWith(Parameterized.class)
public class TemplateValidatorParameterizedTest {

  @SuppressWarnings("unchecked")
  @Parameterized.Parameters(name = "{0}")
  public static Collection<Object[]> data() throws Exception {
    Yaml yaml = new Yaml(new CloudFormationConstructor());
    TemplateValidator validator = new TemplateValidator("redis-rules.yaml");
    InputStream testCaseStream = ClassLoader.getSystemResourceAsStream("redis-test-cases.yaml");
    List<Map<Object, Object>> testCasesRaw = (List<Map<Object, Object>>) yaml.load(testCaseStream);
    List<TestCase> testCases = new ObjectMapper().convertValue(testCasesRaw, new TypeReference<List<TestCase>>() {});

    List<Object[]> list = new ArrayList<>();
    testCases.forEach(testCase -> {
      Object[] test = new Object[] {testCase.description, testCase.errors, testCase.template, validator};

      list.add(test);
    });

    return list;
  }

  private List<String> errors;
  private JsonNode template;
  private TemplateValidator validator;

  public TemplateValidatorParameterizedTest(String description, List<String> errors, JsonNode template, TemplateValidator validator) {
    this.errors = errors;
    this.template = template;
    this.validator = validator;
  }

  @Test
  public void check() {
    List<String> actualErrors = validator.check(template);
    assertThat(actualErrors).isEqualTo(errors);
  }
}
