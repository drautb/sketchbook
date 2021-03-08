/*
 * © 2021 by Intellectual Reserve, Inc. All rights reserved.
 */
package io.github.drautb;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.collect.Iterables;
import org.apache.commons.io.FileUtils;
import org.apache.commons.text.similarity.LevenshteinDistance;
import org.familysearch.ace.common.util.GedcomxMarshallUtil;
import org.familysearch.ace.nlp.core.model.EntityRelation;
import org.familysearch.ace.nlp.token.Tokenizer;
import org.familysearch.ace.stuff.LabeledToken;
import org.familysearch.research.recognizer.relationrecognizer.CorefResolver;
import org.gedcomx.Gedcomx;
import org.gedcomx.conclusion.Document;
import org.gedcomx.conclusion.Name;
import org.gedcomx.conclusion.NameForm;
import org.gedcomx.conclusion.Person;
import org.gedcomx.rt.json.GedcomJacksonModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.logstash.logback.argument.StructuredArguments.keyValue;
import static org.familysearch.ace.nlp.core.model.EntityRelationType.IS_PRINCIPAL;

public class DataGatherer {

  private static final Logger LOG = LoggerFactory.getLogger(DataGatherer.class);

  private static final Pattern PERSON_PATTERN = Pattern.compile("<ENAMEX TYPE=\"PERSON\">\\s*(.*?)\\s*</ENAMEX>");
  private static final Pattern BUILD_PATTERN = Pattern.compile(".*(b\\d+).*");

  private ObjectMapper objectMapper = GedcomJacksonModule.createObjectMapper(); // Non-gedcomx mappers should just instantiate a new ObjectMapper
  private GedcomxMarshallUtil gxUtil = new GedcomxMarshallUtil(objectMapper);
  private Tokenizer tokenizer = new Tokenizer();
  private LevenshteinDistance levenshteinDistance = new LevenshteinDistance();

  public void reap(String dir) throws Exception {
    final Matcher matcher = BUILD_PATTERN.matcher(dir);
    String build = "unknown";
    if (matcher.matches()) {
      build = matcher.group(1);
    }

    final Set<Path> directories = listDirectories(dir);

    for (Path p : directories) {
      gatherDataforLabel(build, p);
    }
  }

  @SuppressWarnings("java:S3457")
  private void gatherDataforLabel(String build, Path path) throws Exception {
    final String label = path.toFile().getName();

    try {
      final Gedcomx generated = loadGedcomx(path, "gedcomx.json");
      final Gedcomx truth = loadGedcomx(path, "truth-gedcomx.json");

      final List<String> generatedNames = principalNames(generated);
      final String truthName = Iterables.getOnlyElement(principalNames(truth), "");
      final Document relexPreRules = getDocument(generated, "relexPreRules");
      final Document relexPostRules = getDocument(generated, "relexPostRules");
      final List<String> personNames = getPersonEntityNames(relexPreRules);
      final List<String> preRulesPrincipalNames = new ArrayList<>(getPrincipalNamesFromRelex(relexPreRules));
      final List<String> postRulesPrincipalNames = new ArrayList<>(getPrincipalNamesFromRelex(relexPostRules));

      double nameMatchScore = truthName.isEmpty() ? 0.0 : getBestNameMatchScore(generatedNames, truthName);
      double bestPersonNameMatchScore = truthName.isEmpty() ? 0.0 : getBestNameMatchScore(personNames, truthName);
      double bestPreRulePrincipalNameMatchScore = truthName.isEmpty() ? 0.0 : getBestNameMatchScore(preRulesPrincipalNames, truthName);
      double bestPostRulePrincipalNameMatchScore = truthName.isEmpty() ? 0.0 : getBestNameMatchScore(postRulesPrincipalNames, truthName);

      LOG.info("summary data",
          keyValue("build", build),
          keyValue("label", label),
          keyValue("principalCount", countPrincipals(generated)),
          keyValue("principalsWithNames", generatedNames.stream().filter(name -> !name.equals("?")).count()),
          keyValue("truthPrincipalCount", countPrincipals(truth)),
          keyValue("principalNames", generatedNames),
          keyValue("truthPrincipalName", truthName),
          keyValue("bestPrincipalNameMatchScore", nameMatchScore),
          keyValue("personEntityNames", personNames),
          keyValue("bestPersonNameMatchScore", bestPersonNameMatchScore),
          keyValue("preRulesPrincipalNames", preRulesPrincipalNames),
          keyValue("bestPreRulesPrincipalNameMatchScore", bestPreRulePrincipalNameMatchScore),
          keyValue("postRulesPrincipalNames", postRulesPrincipalNames),
          keyValue("bestPostRulesPrincipalNameMatchScore", bestPostRulePrincipalNameMatchScore)
          );
    }
    catch(Exception e) {
      LOG.error("An error occurred.", keyValue("label", label), e);
      throw e;
    }
  }

  private Set<String> getPrincipalNamesFromRelex(Document document) {
    final String text = Optional.ofNullable(document.getText()).orElse("");
    final Set<String> relations = new HashSet<>();
    final List<LabeledToken> tokens = tokenizer.parseForRelexToGedcomxConversion(text, relations);
    final CorefResolver corefResolver = new CorefResolver(relations, tokens);

    return relations.stream()
        .map(relationString -> EntityRelation.fromRelex(relationString, tokens))
        .filter(entityRelation -> IS_PRINCIPAL.equals(entityRelation.getKnownType()))
        .map(EntityRelation::getSubject)
        .map(namedEntity -> Optional.ofNullable(corefResolver.getCorefParentTokenByOffset(namedEntity.getOffset())).orElse(namedEntity.getToken()))
        .map(LabeledToken::getText)
        .collect(Collectors.toSet());
  }

  private List<String> getPersonEntityNames(Document document) {
    final Matcher matcher = PERSON_PATTERN.matcher(Optional.ofNullable(document.getText()).orElse(""));
    final List<String> personEntities = new ArrayList<>();
    while (matcher.find()) {
      personEntities.add(matcher.group(1));
    }
    return personEntities;
  }

  private Document getDocument(Gedcomx gedcomx, String documentId) {
    return Optional.ofNullable(gedcomx.getDocuments()).orElse(Collections.emptyList()).stream()
        .filter(document -> documentId.equals(document.getId()))
        .findFirst()
        .orElse(new Document());
  }

  private double getBestNameMatchScore(List<String> generatedNames, String truthName) {
    final String lowerTruthName = truthName.toLowerCase();
    return generatedNames.stream()
        .map(String::toLowerCase)
        .map(name -> {
          if (name.equals(lowerTruthName)) {
            return 1.0;
          } else {
            double score = levenshteinSimilarity(lowerTruthName, name);
            if ((lowerTruthName.contains(name) || name.contains(lowerTruthName)) && score < 0.4) {
              return 0.4;
            }
            return score;
          }
        })
        .max(Double::compareTo)
        .orElse(0.0);
  }

  private Stream<Person> principals(Gedcomx gedcomx) {
    return Optional.ofNullable(gedcomx.getPersons()).orElse(Collections.emptyList()).stream()
        .filter(p -> Optional.ofNullable(p.getPrincipal()).orElse(false));
  }

  private long countPrincipals(Gedcomx gx) {
    return principals(gx).count();
  }

  private List<String> principalNames(Gedcomx gx) {
    return principals(gx)
        .map(Person::getName)
        .filter(Objects::nonNull)
        .flatMap(Name::nameForms)
        .filter(Objects::nonNull)
        .map(NameForm::getFullText)
        .collect(Collectors.toList());
  }

  private Set<Path> listDirectories(String dir) throws Exception {
    try (Stream<Path> stream = Files.list(Paths.get(dir))) {
      return stream
          .filter(Files::isDirectory)
          .collect(Collectors.toSet());
    }
  }

  private double levenshteinSimilarity(String string1, String string2) {
    return (1 - ((double) levenshteinDistance.apply(string1, string2) / Math.max(string1.length(), string2.length())));
  }

  private Gedcomx loadGedcomx(Path dir, String name) throws Exception {
    final String contents = FileUtils.readFileToString(dir.resolve(name).toFile(), StandardCharsets.UTF_8);
    return gxUtil.unmarshallToGedcomx(contents).get(0);
  }

}
