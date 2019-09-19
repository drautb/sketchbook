package io.github.drautb.cfnrules;

import com.fasterxml.jackson.databind.JsonNode;
import org.jeasy.rules.api.Facts;
import org.jeasy.rules.api.Rules;
import org.jeasy.rules.core.DefaultRulesEngine;
import org.jeasy.rules.mvel.MVELRuleFactory;
import org.jeasy.rules.support.YamlRuleDefinitionReader;

import java.io.File;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.List;

/**
 * @author drautb
 */
public class TemplateValidator {

  private JmesPathWrapper jmesPathWrapper;
  private Rules rules;

  public TemplateValidator(String rulesFile) throws Exception {
    this.jmesPathWrapper = new JmesPathWrapper();
    this.rules = loadRules(rulesFile);
  }

  public List<String> check(String resourceFile) throws Exception {
    jmesPathWrapper.loadDataFromResources(resourceFile);
    return check();
  }

  public List<String> check(JsonNode data) {
    jmesPathWrapper.loadData(data);
    return check();
  }

  private List<String> check() {
    List<String> errors = new ArrayList<>();

    // Add jp and errors to the facts to make them available in the rules.
    Facts facts = new Facts();
    facts.put("errors", errors);
    facts.put("jp", jmesPathWrapper);

    DefaultRulesEngine rulesEngine = new DefaultRulesEngine();
    rulesEngine.registerRuleListener(new EarlyReturnListener());
    rulesEngine.fire(rules, facts);

    return errors;
  }

  private Rules loadRules(String rulesFile) throws Exception {
    MVELRuleFactory ruleFactory = new MVELRuleFactory(new YamlRuleDefinitionReader());
    return ruleFactory.createRules(new FileReader(new File(ClassLoader.getSystemResource(rulesFile).toURI())));
  }

}
