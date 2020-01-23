package io.github.drautb.cdk;

import software.amazon.awscdk.core.App;

public final class CdkTestApp {

  public static void main(final String[] args) {
    App app = new App();

    new CdkTestStack(app, "drautb-cdk-test-stack");

    app.synth();
  }

}
