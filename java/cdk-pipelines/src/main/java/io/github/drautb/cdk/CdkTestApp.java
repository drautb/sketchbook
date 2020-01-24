package io.github.drautb.cdk;

import io.github.drautb.cdk.model.IntermediateRepresentation;
import software.amazon.awscdk.core.App;

public final class CdkTestApp {

  public static void main(final String[] args) {
    App app = new App();

    IntermediateRepresentation ir = IntermediateRepresentation.loadIR();
    new CdkTestStack(app, "adhoc-drautb-cdk-" + ir.getName());

    app.synth();
  }

}
