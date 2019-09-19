package io.github.drautb.cfnrules;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.burt.jmespath.Expression;
import io.burt.jmespath.JmesPath;
import io.burt.jmespath.jackson.JacksonRuntime;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;

/**
 *
 * @author drautb
 */
public class JmesPathWrapper {

  private static final Logger LOG = LoggerFactory.getLogger(JmesPathWrapper.class);
  private static final ObjectMapper MAPPER = new ObjectMapper();

  private JmesPath<JsonNode> jmesPath;
  private JsonNode data;

  public JmesPathWrapper() {
    this(new JacksonRuntime());
  }

  public JmesPathWrapper(JmesPath<JsonNode> jmesPath) {
    this.jmesPath = jmesPath;
  }

  public void loadData(JsonNode data) {
    this.data = data.deepCopy();
  }

  public void loadDataFromResources(String dataFile) throws Exception {
    File f = new File(ClassLoader.getSystemResource(dataFile).toURI());
    loadData(MAPPER.readValue(f, JsonNode.class));
  }

  public Object q(String queryStr) {
    Expression<JsonNode> expression = jmesPath.compile(queryStr);
    JsonNode result = expression.search(data);

    LOG.debug("Result type={}", result.getNodeType());
    if (result.isNull()) {
      return null;
    }
    else if (result.isBoolean()) {
      return result.asBoolean();
    }
    else if (result.isNumber()) {
      return result.numberValue();
    }
    else if (result.isTextual()) {
      return result.textValue();
    }
    else if (result.isArray()) {
      return StreamSupport
          .stream(result.spliterator(), false)
          .collect(Collectors.toList());
    }
    else {
      return result;
    }
  }

}
