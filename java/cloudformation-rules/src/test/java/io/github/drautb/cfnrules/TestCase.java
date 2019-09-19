package io.github.drautb.cfnrules;

import com.fasterxml.jackson.databind.JsonNode;

import java.util.List;

/**
 * @author drautb
 */
public class TestCase {

  public String description;
  public JsonNode template;
  public List<String> errors;

}
