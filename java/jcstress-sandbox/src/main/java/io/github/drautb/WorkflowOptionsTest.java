package io.github.drautb;

import org.familysearch.paas.sps.config.api.ProvisionerVersionLookup;
import org.familysearch.paas.sps.config.api.ProvisionerVersionLookupFactory;
import org.openjdk.jcstress.annotations.*;

import org.openjdk.jcstress.infra.results.StringResult2;

/**
 * @author drautb
 */
@JCStressTest
@Outcome(id = "0.0.3, 0.0.5", expect = Expect.ACCEPTABLE, desc = "SQS then S3")
@Outcome(id = "0.0.5, 0.0.3", expect = Expect.ACCEPTABLE, desc = "S3 then SQS")
@Outcome(id = "0.0.3, 0.0.3", expect = Expect.FORBIDDEN, desc = "Both SQS")
@Outcome(id = "0.0.5, 0.0.5", expect = Expect.FORBIDDEN, desc = "Both S3")
@State
public class WorkflowOptionsTest {

  private static final String DOMAIN = "paas-sps";

  private static ProvisionerVersionLookupFactory provisionerVersionLookupFactory = new ProvisionerVersionLookupFactory();

  @Actor
  public void actor1(StringResult2 s) {
    ProvisionerVersionLookup lookup = provisionerVersionLookupFactory.getProvisionerVersionLookup();
    s.r1 = lookup.getVersion(DOMAIN, "s3");
  }

  @Actor
  public void actor2(StringResult2 s) {
    ProvisionerVersionLookup lookup = provisionerVersionLookupFactory.getProvisionerVersionLookup();
    s.r2 = lookup.getVersion(DOMAIN, "sqs");
  }

}
