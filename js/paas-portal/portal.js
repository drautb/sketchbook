/**
 * Setup:
 *
 * `npm install -g casperjs`
 */
var casper = require('casper').create({
  verbose: true,
  logLevel: 'warning'
});

casper.start('https://dptservices.familysearch.org/portal');

var username = casper.cli.get(0),
    password = casper.cli.get(1);

casper.then(function() {
  this.click('div#login-button a');
});

casper.thenEvaluate(function(username, password) {
  document.querySelector('input[name="IDToken1"]').setAttribute('value', username);
  document.querySelector('input[name="IDToken2"]').setAttribute('value', password);
  document.querySelector('form[name="Login"]').submit();
}, username, password);

var jSessionId = '';
var fspSessionId = '';

casper.then(function() {
  phantom.cookies.forEach(function(c) {
    if (c.name === 'JSESSIONID') {
      jSessionId = c.value;
    }
    else if (c.name === 'fspSessionId') {
      fspSessionId = c.value;
    }
  });

  console.log(jSessionId + ' ' + fspSessionId);
});

casper.run();
