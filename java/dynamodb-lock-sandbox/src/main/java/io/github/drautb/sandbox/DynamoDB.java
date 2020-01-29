package io.github.drautb.sandbox;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.local.embedded.DynamoDBEmbedded;
import com.amazonaws.services.dynamodbv2.local.shared.access.AmazonDynamoDBLocal;
import com.amazonaws.services.dynamodbv2.model.*;
import org.springframework.stereotype.Component;

import javax.annotation.PreDestroy;
import java.util.Collections;

@Component
public class DynamoDB {

  public static final String TABLE_NAME = "lock-table";
  public static final String HASH_KEY_LOCK_NAME = "lock_name";

  private AmazonDynamoDBLocal amazonDynamoDBLocal;

  public DynamoDB() {
    amazonDynamoDBLocal = DynamoDBEmbedded.create();

    AmazonDynamoDB dynamoDB = getDynamoDbClient();

    CreateTableRequest request = new CreateTableRequest(TABLE_NAME,
        Collections.singletonList(new KeySchemaElement(HASH_KEY_LOCK_NAME, "HASH")))
        .withAttributeDefinitions(new AttributeDefinition(HASH_KEY_LOCK_NAME, "S"))
        // This is required, but meaningless when running locally.
        // See :https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamoDBLocal.UsageNotes.html#DynamoDBLocal.Differences
        .withProvisionedThroughput(new ProvisionedThroughput(1L, 1L));
    CreateTableResult result = dynamoDB.createTable(request);
    result.getTableDescription();
  }

  @PreDestroy
  public void destroy() {
    amazonDynamoDBLocal.shutdown();
  }

  public AmazonDynamoDB getDynamoDbClient() {
    return amazonDynamoDBLocal.amazonDynamoDB();
  }
}
