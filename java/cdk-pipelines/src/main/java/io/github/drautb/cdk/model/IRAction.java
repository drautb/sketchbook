package io.github.drautb.cdk.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import software.amazon.awscdk.services.codebuild.ComputeType;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@JsonIgnoreProperties(ignoreUnknown = true)
public class IRAction {

  private String name;
  private ComputeType size;
  private Map<String, String> runtimeVersions;
  private Integer runOrder;
  private List<String> commands;

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public ComputeType getSize() {
    return size;
  }

  public void setSize(ComputeType size) {
    this.size = size;
  }

  public Map<String, String> getRuntimeVersions() {
    return runtimeVersions;
  }

  public void setRuntimeVersions(Map<String, String> runtimeVersions) {
    this.runtimeVersions = runtimeVersions;
  }

  public Integer getRunOrder() {
    return runOrder;
  }

  public void setRunOrder(Integer runOrder) {
    this.runOrder = runOrder;
  }

  public List<String> getCommands() {
    return commands;
  }

  public void setCommands(List<String> commands) {
    this.commands = commands;
  }

  /**
   * Helper method to generate the CodeBuild Buildspec for this action.
   *
   * TODO: Allow overrides such that things like runtime-versions and environment variables
   * can be configured in the IR for an entire pipeline or stage, rather than being required
   * on every action.
   */
  public Map<String, Object> generateBuildSpec() {
    Map<String, Object> buildSpec = new HashMap<>();
    buildSpec.put("version", "0.2");

    Map<String, Object> phases = new HashMap<>();
    buildSpec.put("phases", phases);

    Map<String, Object> installPhase = new HashMap<>();
    installPhase.put("runtime-versions", runtimeVersions);
    phases.put("install", installPhase);

    Map<String, Object> buildPhase = new HashMap<>();
    buildPhase.put("commands", commands);
    phases.put("build", buildPhase);

    return buildSpec;
  }

}
