package io.github.drautb.cdk;

import org.yaml.snakeyaml.Yaml;
import software.amazon.awscdk.core.Construct;
import software.amazon.awscdk.core.Stack;
import software.amazon.awscdk.core.StackProps;
import software.amazon.awscdk.services.codebuild.*;
import software.amazon.awscdk.services.iam.IManagedPolicy;
import software.amazon.awscdk.services.iam.ManagedPolicy;
import software.amazon.awscdk.services.iam.Role;
import software.amazon.awscdk.services.iam.ServicePrincipal;
import software.amazon.awscdk.services.s3.Bucket;

import java.util.Map;

public class CdkTestStack extends Stack {

  public CdkTestStack(final Construct parent, final String id) {
    this(parent, id, null);
  }

  public CdkTestStack(final Construct parent, final String id, final StackProps props) {
    super(parent, id, props);

    final IManagedPolicy boundaryPolicy = ManagedPolicy.fromManagedPolicyName(this, "boundaryPolicy", "org-1/FHDT_AccountBoundary");

    final Role role = Role.Builder.create(this, "CodeBuildRole")
        .assumedBy(new ServicePrincipal("codebuild.amazonaws.com"))
        .permissionsBoundary(boundaryPolicy)
        .build();

    Project.Builder.create(this, "CodeBuildProject")
        .buildSpec(BuildSpec.fromObject(getBuildSpec()))
        .source(Source.s3(S3SourceProps.builder().bucket(Bucket.fromBucketName(this, "bucket", "adhoc-drautb-dpt-dev")).path("input/message-util.zip").build()))
        .artifacts(Artifacts.s3(S3ArtifactsProps.builder().name("messageUtil-1.0.jar").bucket(Bucket.fromBucketName(this, "outputBucket", "adhoc-drautb-dpt-dev")).path("output").build()))
        .environment(BuildEnvironment.builder().buildImage(LinuxBuildImage.AMAZON_LINUX_2_2).computeType(ComputeType.LARGE).build())
        .role(role)
        .build();
  }

  private Map<String, Object> getBuildSpec() {
    Yaml yaml = new Yaml();

    try {
      return yaml.load(this.getClass().getClassLoader().getResourceAsStream("buildspec.yml"));
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }

}
