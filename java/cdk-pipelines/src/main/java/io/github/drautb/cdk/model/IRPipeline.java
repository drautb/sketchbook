package io.github.drautb.cdk.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class IRPipeline {

  private String name;
  private List<IRStage> stages;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public List<IRStage> getStages() {
    return stages;
  }

  public void setStages(List<IRStage> stages) {
    this.stages = stages;
  }

}
