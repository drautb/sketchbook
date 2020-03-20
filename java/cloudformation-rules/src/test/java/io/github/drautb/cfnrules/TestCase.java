package io.github.drautb.cfnrules;

import com.fasterxml.jackson.databind.JsonNode;
import org.jeasy.rules.api.Facts;

import java.util.List;
import java.util.Map;

/**
 * @author drautb
 */
public class TestCase {

  public String description;
  public JsonNode template;
  public List<String> errors;
  public Map<String, Object> facts;

}
