package io.github.drautb.cfnrules;

import org.jeasy.rules.api.Facts;
import org.jeasy.rules.api.Rule;
import org.jeasy.rules.core.BasicRule;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * @author drautb
 */
public class EarlyReturnListenerTest {

  private Rule rule;
  private Facts facts;
  private List<String> errors;

  private EarlyReturnListener testModel;

  @BeforeEach
  public void setup() {
    rule = new BasicRule();
    facts = new Facts();
    errors = new ArrayList<>();

    facts.put("errors", errors);

    testModel = new EarlyReturnListener();
  }

  @Test
  public void beforeEvaluate_shouldReturnTrueIfErrorsAlreadyExist() {
    errors.add("test-error");

    assertThat(testModel.beforeEvaluate(rule, facts)).isTrue();
  }

  @Test
  public void beforeEvaluate_shouldReturnFalseIfErrorsOccurredInAnOlderPriorityTier() {
    rule = new BasicRule(Rule.DEFAULT_NAME, Rule.DEFAULT_DESCRIPTION, 2);
    facts.put("p", 1);
    errors.add("test-error");

    assertThat(testModel.beforeEvaluate(rule, facts)).isFalse();
  }

  @Test
  public void beforeEvaluate_shouldReturnTrueIfErrorsOccurredInCurrentPriorityTier() {
    rule = new BasicRule(Rule.DEFAULT_NAME, Rule.DEFAULT_DESCRIPTION, 1);
    facts.put("p", 1);
    errors.add("test-error");

    assertThat(testModel.beforeEvaluate(rule, facts)).isTrue();
  }

  @Test
  public void beforeEvaluate_shouldUpdateTheCurrentPriority() {
    rule = new BasicRule(Rule.DEFAULT_NAME, Rule.DEFAULT_DESCRIPTION, 2);
    facts.put("p", 1);

    assertThat(testModel.beforeEvaluate(rule, facts)).isTrue();
    assertThat(facts.asMap()).containsEntry("p", 2);
  }

}
