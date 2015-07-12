/*
  Sends an email confirmation of the home teaching report to the submitter.

  * On the _responses_ spreadsheet, click Tools -> Script Editor.
  * Copy/paste this code.
  * Run the "Initialize" function.
 */

function Initialize() {
  var triggers = ScriptApp.getProjectTriggers();

  for (var t in triggers) {
    ScriptApp.deleteTrigger(triggers[t]);
  }

  ScriptApp.newTrigger("SendConfirmationEmail")
    .forSpreadsheet(SpreadsheetApp.getActiveSpreadsheet())
    .onFormSubmit()
    .create();
}


function SendConfirmationEmail(event) {
  var pp6Email = Session.getActiveUser().getEmail(),
      senderName = "West Elder's Quorum - Provo Peak 6th Ward",
      subject = "Home Teaching Report Received";

  var spreadsheet = SpreadsheetApp.getActiveSheet();
  var columns = spreadsheet.getRange(1, 1, 1, spreadsheet.getLastColumn()).getValues()[0];

  var sendTo = event.values[2].toString();

  var messageBody = "<html><body><table border=\"1\"><tr><th>Question</th><th>Answer</th></tr>";

  for (var k in columns) {
    var key = columns[k];
    if (event.namedValues[key]) {
      messageBody += "<tr><td width=\"50%\"><strong>" + key + "</strong></td><td width=\"50%\">" + event.namedValues[key] + "</td></tr>";
    }
  }

  messageBody += "</table></body></html>";

  MailApp.sendEmail(sendTo, subject, messageBody, {htmlBody: messageBody, cc: pp6Email, name: "West Elder's Quorum - Provo Peak 6th Ward"});
}
