package io.github.drautb.sandbox;

import com.amazonaws.services.dynamodbv2.AcquireLockOptions;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBLockClient;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBLockClientOptions;
import com.amazonaws.services.dynamodbv2.LockItem;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.util.ReflectionUtils;

import java.lang.reflect.Field;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Component
public class PeriodicTask {

  private static final Logger LOG = LoggerFactory.getLogger(PeriodicTask.class);

  private static final String LOCK_NAME = "the-lock";

  private static final long LEASE_DURATION_SECONDS = 5L;

  @Autowired
  private DynamoDB dynamoDB;

  @Scheduled(fixedRate = 1000L)
  public void getLock1() throws InterruptedException {
    go();
  }

  @Scheduled(fixedRate = 1000L)
  public void getLock2() throws InterruptedException {
    go();
  }

  @Scheduled(fixedRate = 1000L)
  public void getLock3() throws InterruptedException {
    go();
  }

  private void go() throws InterruptedException {
    String threadName = Thread.currentThread().getName();

    AmazonDynamoDBLockClient lockClient = new AmazonDynamoDBLockClient(
        AmazonDynamoDBLockClientOptions.builder(dynamoDB.getDynamoDbClient(), DynamoDB.TABLE_NAME)
            .withCreateHeartbeatBackgroundThread(false)
            .withPartitionKeyName(DynamoDB.HASH_KEY_LOCK_NAME)
            .withLeaseDuration(LEASE_DURATION_SECONDS)
            .withTimeUnit(TimeUnit.SECONDS)
            .withOwnerName("sauron")
            .build());

    Field ownerField = ReflectionUtils.findField(AmazonDynamoDBLockClient.class, "ownerName");
    ReflectionUtils.makeAccessible(ownerField);
    String ownerName = (String) ReflectionUtils.getField(ownerField, lockClient);
    LOG.info("Trying to acquire lock. thread={} owner={}", threadName, ownerName);
    Optional<LockItem> optionalLock = lockClient.tryAcquireLock(
        AcquireLockOptions.builder(LOCK_NAME)
            .withDeleteLockOnRelease(true)
            .build());

    if (optionalLock.isPresent()) {
      LOG.info("Lock acquired! Not releasing lock. thread={} owner={}", threadName, ownerName);
    }
    else {
      LOG.info("Lock acquisition failed! thread={} owner={}", threadName, ownerName);
    }
  }

}
