package io.github.drautb.cdk.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public class IRStage {

  private String name;
  private List<IRAction> actions;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public List<IRAction> getActions() {
    return actions;
  }

  public void setActions(List<IRAction> actions) {
    this.actions = actions;
  }
}
