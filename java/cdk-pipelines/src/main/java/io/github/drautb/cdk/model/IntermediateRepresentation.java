package io.github.drautb.cdk.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;

import java.io.File;
import java.util.List;

/**
 * Represents the intermediate representation for a blueprint.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class IntermediateRepresentation {

  private String name;

  private List<IRPipeline> pipelines;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public List<IRPipeline> getPipelines() {
    return pipelines;
  }

  public void setPipelines(List<IRPipeline> pipelines) {
    this.pipelines = pipelines;
  }

  public static final IntermediateRepresentation loadIR() {
    ObjectMapper mapper = new ObjectMapper(new YAMLFactory());

    try {
      return mapper.readValue(
          new File("src/main/resources/ir.yml"),
          IntermediateRepresentation.class);
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

}
