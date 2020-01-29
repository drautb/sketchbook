package io.github.drautb.sandbox;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@EnableScheduling
@SpringBootApplication
public class App {

  private static final Logger LOG = LoggerFactory.getLogger(App.class);

  public static void main(String[] args) {
    LOG.info("Starting App...");
    new SpringApplication(App.class).run(args);
  }

}
