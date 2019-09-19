package io.github.drautb.thesisqueue;

import com.gargoylesoftware.htmlunit.WebClient;
import com.gargoylesoftware.htmlunit.html.HtmlForm;
import com.gargoylesoftware.htmlunit.html.HtmlHeading1;
import com.gargoylesoftware.htmlunit.html.HtmlPage;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.List;

@SpringBootApplication
public class App {

  public static void main(String[] args) throws Exception {
    try (final WebClient webClient = new WebClient()) {
      HtmlPage loginPage = webClient.getPage("https://go.utah.edu/cas/login");

      HtmlForm loginForm = null;
      List<HtmlForm> forms = loginPage.getForms();
      for (HtmlForm f : forms) {
        if (f.getAttribute("id").equals("fm1")) {
          loginForm = f;
          break;
        }
      }

      loginForm.getInputByName("username").type(System.getenv("UTAH_USERNAME"));
      loginForm.getInputByName("password").type(System.getenv("UTAH_PASSWORD"));
      loginForm.getInputByName("submit").click();

      // Navigate to thesis status.
      HtmlPage thesisQueuePage = webClient.getPage("https://thesis.gradschool.utah.edu/thesis-status/");
      HtmlHeading1 queueH1 = (HtmlHeading1) thesisQueuePage.getByXPath("//*[@id=\"student-content\"]/h1").get(0);
      String queueText = queueH1.getFirstChild().getNodeValue();
      System.out.println(queueText.split(" ")[1]);
    }
  }

}
