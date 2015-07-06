#!/usr/bin/env ruby

require 'aws-sdk'

$stdout.sync = true

WORKFLOW_INPUT = <<INPUT
[
  {
    "blueprintName": "paas-sps-sqs",
    "syspsWorkflowId": "paas-sps-sqs,dev,integrate,ec-1396548",
    "systemName": "dev",
    "serviceName": "workers",
    "buildNumber": "42",
    "buildSnapshotUrl": "https://mvn.fsglobal.net/content/repositories/approved/org/familysearch/cdo/deploys/paas-sps-sqs-checkout/42/paas-sps-sqs-checkout-42.zip",
    "definition": {
      "location": "development-fh5-useast1-primary-1",
      "type": "beanstalk",
      "path_to_artifact": "provisioner/target/paas-sps-sqs-provisioner.war",
      "stack_name": "64bit Amazon Linux 2014.09 v1.1.0 running Tomcat 7 Java 7",
      "instance_type": "t2.small",
      "autoscale_options": {
        "min_instances": 1,
        "max_instances": 1
      },
      "experiments": [
        "paas_sps_beanstalk_v10_Experiment",
        "awsProxyExperiment",
        "blueprintDeployRunsAcceptanceTests",
        "deleteBeforeTestsExperiment",
        "dockerArtifactoryExperiment",
        "downstreamIntegrationTriggerExperiment",
        "explicitVersionRollbackExperiment",
        "failOnKnownIncompatibilitiesExperiment",
        "filterDependenciesExperiment",
        "inlineDependencyManagementExperiment",
        "instanceProfiles",
        "javaBeanstalkUpdater",
        "javaS3UploaderExperiment",
        "justBaselineInIPWhatChangedReportExperiment",
        "maxJavaVersionExperiment",
        "paas_sysps_ruby_v10_integrate",
        "recompileConsumedModulesExperiment",
        "thoroughRecompileCheckExperiment",
        "triggerDownstreamsUsingSlideDataExperiment",
        "updateParentExperiment",
        "useComponentManifestExperiment",
        "useVersionChooserExperiment",
        "versionChooser2Experiment",
        "talkToDtmExperiment"
      ],
      "references": [
        "swf"
      ]
    },
    "triggerURL": "git@github.com:fs-eng/paas-sps-sqs",
    "triggerRev": "702ebaa425a94365c3f1a42058444c726c9a82fd"
  },
  {
    "deployId": "42-334307368",
    "testEnvVars": {
      "WORKERS_APP_ENV_NAME": "42-334307368",
      "DEV_WORKERS_URL": "internal-awseb-e-8-AWSEBLoa-188NBPBCYPDRM-1521433022.us-east-1.elb.amazonaws.com"
    }
  }
]
INPUT

@swf_client = Aws::SWF::Client.new(region: 'us-east-1')

def start_execution(workflow_id)
  puts "Starting execution '#{workflow_id}'..."

  @swf_client.start_workflow_execution({:domain => "paas-sps-dev",
                                       :workflow_id => workflow_id,
                                       :workflow_type => {:name => "BeanstalkProvisioner.integrate", :version => "0.0.10"},
                                       :input => WORKFLOW_INPUT})
end

for n in 1..20
  sleep(10)
  start_execution("drautb-dtm-#{n}")
end




