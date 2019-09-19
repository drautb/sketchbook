package io.github.drautb.cfnrules;

import org.jeasy.rules.api.Facts;
import org.jeasy.rules.api.Rule;
import org.jeasy.rules.api.RuleListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * A custom rule listener that will skip rules in later groups (lower priority) if errors were found in
 * earlier groups.
 *
 * @author drautb
 */
public class EarlyReturnListener implements RuleListener {

  private static final Logger LOG = LoggerFactory.getLogger(EarlyReturnListener.class);

  private static final String PRIORITY_KEY = "p";

  @Override
  public boolean beforeEvaluate(Rule rule, Facts facts) {
    LOG.debug("beforeEvaluate: {}", rule.getName());

    if (facts.asMap().containsKey(PRIORITY_KEY)) {
      int currentPriority = facts.get(PRIORITY_KEY);
      if (rule.getPriority() > currentPriority && !((List)facts.get("errors")).isEmpty()) {
        LOG.info("Skipping rule due to errors in higher-priority rules. rule={}", rule.getName());
        return false;
      }
    }

    facts.put(PRIORITY_KEY, rule.getPriority());
    return true;
  }

  @Override
  public void afterEvaluate(Rule rule, Facts facts, boolean b) {
    LOG.debug("afterEvaluate: {} - {}", rule.getName(), b);
  }

  @Override
  public void beforeExecute(Rule rule, Facts facts) {
    LOG.debug("beforeExecute: {}", rule.getName());
  }

  @Override
  public void onSuccess(Rule rule, Facts facts) {
    LOG.debug("onSuccess: {}", rule.getName());
  }

  @Override
  public void onFailure(Rule rule, Facts facts, Exception e) {
    LOG.error("onFailure: rule={} facts={}", rule.getName(), facts, e);
    throw new RuntimeException(e);
  }
}
