package io.github.drautb.cfnrules;

import org.yaml.snakeyaml.constructor.AbstractConstruct;
import org.yaml.snakeyaml.constructor.SafeConstructor;
import org.yaml.snakeyaml.nodes.Node;
import org.yaml.snakeyaml.nodes.ScalarNode;
import org.yaml.snakeyaml.nodes.SequenceNode;
import org.yaml.snakeyaml.nodes.Tag;

import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * This is a utility class that causes the YAML parser to rewrite the AWS CFN
 * YAML Tags, like !Ref, !Sub, etc. as normal key/value structure.
 *
 * @author drautb
 */
public class CloudFormationConstructor extends SafeConstructor {

  private static final List<String> CFN_TAGS = Arrays.asList("!Ref", "!If");

  private static final Map<String, String> TAG_KEY_LOOKUP = Collections.unmodifiableMap(
      Stream.of(new String[][] {
        { "!Ref", "Ref" },
        { "!If",  "Fn::If" },
      }).collect(Collectors.toMap(data -> data[0], data -> data[1])));

  public CloudFormationConstructor() {
    for (String tagKey : CFN_TAGS) {
      this.yamlConstructors.put(new Tag(tagKey), new ShorthandTagConstructor());
    }
  }

  private class ShorthandTagConstructor extends AbstractConstruct {
    public Object construct(Node n) {
      Map<String, Object> newNode = new HashMap<>();
      String newKey = TAG_KEY_LOOKUP.get(n.getTag().toString());

      Object newValue;
      if (n instanceof ScalarNode) {
        newValue = constructScalar((ScalarNode) n);
      }
      else if (n instanceof SequenceNode) {
        newValue = constructSequence((SequenceNode) n);
      }
      else {
        throw new RuntimeException("Unrecognized node type used with Tag! tag=" + n.getTag() + " type=" + n.getType());
      }

      newNode.put(newKey, newValue);
      return newNode;
    }
  }

}
