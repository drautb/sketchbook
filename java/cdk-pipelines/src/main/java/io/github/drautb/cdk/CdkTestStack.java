package io.github.drautb.cdk;

import io.github.drautb.cdk.model.IRAction;
import io.github.drautb.cdk.model.IRPipeline;
import io.github.drautb.cdk.model.IntermediateRepresentation;
import io.github.drautb.cdk.model.IRStage;
import software.amazon.awscdk.core.*;
import software.amazon.awscdk.services.codebuild.*;
import software.amazon.awscdk.services.codepipeline.Artifact;
import software.amazon.awscdk.services.codepipeline.IAction;
import software.amazon.awscdk.services.codepipeline.Pipeline;
import software.amazon.awscdk.services.codepipeline.StageProps;
import software.amazon.awscdk.services.codepipeline.actions.CodeBuildAction;
import software.amazon.awscdk.services.codepipeline.actions.CodeBuildActionType;
import software.amazon.awscdk.services.codepipeline.actions.S3SourceAction;
import software.amazon.awscdk.services.iam.*;
import software.amazon.awscdk.services.s3.Bucket;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * CDK stack that will deploy a codepipeline based on the intermediate blueprint representation.
 */
public class CdkTestStack extends Stack {

  public CdkTestStack(final Construct parent, final String id) {
    this(parent, id, null);
  }

  public CdkTestStack(final Construct parent, final String id, final StackProps props) {
    super(parent, id, props);

    IntermediateRepresentation ir = IntermediateRepresentation.loadIR();

    // TAGS
    Tag.add(this, "blueprint", "null");
    Tag.add(this, "council", "PlatformSvc-DPT-Provisioning");
    Tag.add(this, "owner", "drautb");

    // PREPARE STORAGE
    final Bucket s3Bucket = Bucket.Builder.create(this, "S3Bucket")
        .bucketName(ir.getName() + "-storage")
        .removalPolicy(RemovalPolicy.DESTROY)
        .build();

    // PREPARE PERMISSIONS
    final IManagedPolicy boundaryPolicy = 
        ManagedPolicy.fromManagedPolicyName(this, "boundaryPolicy", "org-1/FHDT_AccountBoundary");

    final PrincipalBase codeBuildPrincipal = ServicePrincipal.Builder.create("codebuild.amazonaws.com").build();
    final PrincipalBase codePipelinePrincipal = ServicePrincipal.Builder.create("codepipeline.amazonaws.com").build();

    final Role codeBuildRole = Role.Builder.create(this, "CodeBuildRole")
        .assumedBy(new CompositePrincipal(codeBuildPrincipal, codePipelinePrincipal))
        .permissionsBoundary(boundaryPolicy)
        .build();

    final Role codePipelineRole = Role.Builder.create(this, "CodePipelineRole")
        .assumedBy(codePipelinePrincipal)
        .permissionsBoundary(boundaryPolicy)
        .build();

    // BUILD PIPELINES
    for (IRPipeline irPipeline : ir.getPipelines()) {
      List<StageProps> stagePropsList = new ArrayList<>();

      // The first stage, which isn't shown in the IR, contains a single source action to
      // generate the 'checkout' artifact from the code in S3.
      S3SourceAction sourceAction = S3SourceAction.Builder.create()
          .actionName("checkout-source")
          .bucket(s3Bucket)
          .bucketKey("input/" + ir.getName() + "/checkout.zip")
          .output(Artifact.artifact("checkout"))
          .role(codeBuildRole)
          .build();

      stagePropsList.add(StageProps.builder()
          .stageName("prepare-checkout")
          .actions(Collections.singletonList(sourceAction))
          .build());

      for (IRStage stage : irPipeline.getStages()) {
        List<IAction> stageActionsList = new ArrayList<>();

        for (int actionIdx = 0; actionIdx < stage.getActions().size(); actionIdx++) {
          IRAction action = stage.getActions().get(actionIdx);

          BuildEnvironment buildEnvironment = BuildEnvironment.builder()
              .buildImage(LinuxBuildImage.AMAZON_LINUX_2_2)
              .computeType(action.getSize())
              .build();

          PipelineProject project = PipelineProject.Builder
              .create(this, String.join("_", irPipeline.getName(), stage.getName(), String.valueOf(actionIdx)))
              .buildSpec(BuildSpec.fromObject(action.generateBuildSpec()))
              .environment(buildEnvironment)
              .role(codeBuildRole)
              .build();

          CodeBuildAction codeBuildAction = CodeBuildAction.Builder.create()
              .actionName(action.getName())
              .project(project)
              .role(codeBuildRole)
              .runOrder(action.getRunOrder())
              .type(CodeBuildActionType.BUILD) // TODO: is this necessary? build and test are the only options, they don't cover all uses.
              .input(Artifact.artifact("checkout")) // Every action gets the checkout directory as an input.
              .build();

          stageActionsList.add(codeBuildAction);
        }

        StageProps stageProps = StageProps.builder()
            .stageName(stage.getName())
            .actions(stageActionsList)
            .build();
        stagePropsList.add(stageProps);
      }

      Pipeline.Builder.create(this, irPipeline.getName())
          .artifactBucket(s3Bucket)
          .role(codePipelineRole)
          .stages(stagePropsList)
          .build();
    }

  }

}
