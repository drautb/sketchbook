package io.github.drautb.cfnrules;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import io.burt.jmespath.Expression;
import io.burt.jmespath.JmesPath;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;

import java.util.ArrayList;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.mockito.MockitoAnnotations.initMocks;

/**
 * @author drautb
 */
public class JmesPathWrapperTest {

  private static final ObjectMapper MAPPER = new ObjectMapper();

  private static final String QUERY = "query-str";

  @Mock
  private JmesPath<JsonNode> jmesPath;

  @Mock
  private Expression<JsonNode> expression;

  private JmesPathWrapper testModel;

  @BeforeEach
  public void setup() throws Exception {
    initMocks(this);

    when(jmesPath.compile(anyString())).thenReturn(expression);
    when(expression.search(any())).thenReturn(getNode("{}"));

    this.testModel = new JmesPathWrapper(jmesPath);
  }

  private JsonNode getNode(String json) throws Exception {
    return MAPPER.readValue(json, JsonNode.class);
  }

  @Test
  public void q_shouldReturnNullWhenQueryResultIsNull() throws Exception {
    when(expression.search(any())).thenReturn(getNode("null"));

    assertThat(testModel.q(QUERY)).isNull();
  }

  @Test
  public void q_shouldReturnBooleanWhenQueryResultIsBoolean() throws Exception {
    when(expression.search(any())).thenReturn(getNode("true"));

    assertThat(testModel.q(QUERY)).isOfAnyClassIn(Boolean.class);
  }

  @Test
  public void q_shouldReturnNumberWhenQueryResultIsNumeric() throws Exception {
    when(expression.search(any())).thenReturn(getNode("42"));

    assertThat(testModel.q(QUERY)).isOfAnyClassIn(Integer.class);
  }

  @Test
  public void q_shouldReturnStringWhenQueryResultIsTextual() throws Exception {
    when(expression.search(any())).thenReturn(getNode("\"text\""));

    assertThat(testModel.q(QUERY)).isOfAnyClassIn(String.class);
  }

  @Test
  public void q_shouldReturnListWhenQueryResultIsArray() throws Exception {
    when(expression.search(any())).thenReturn(getNode("[]"));

    assertThat(testModel.q(QUERY)).isOfAnyClassIn(ArrayList.class);
  }

  @Test
  public void q_shouldReturnJsonNodeIfQueryResultIsObject() {
    assertThat(testModel.q(QUERY)).isOfAnyClassIn(ObjectNode.class);
  }

}
