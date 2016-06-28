/**
 * Setup:
 *
 * `npm install -g casperjs`
 */
var casper = require('casper').create({
  verbose: true,
  logLevel: 'warning'
});

var username = casper.cli.get(0),
    password = casper.cli.get(1);

casper.start('https://ident.lds.org/sso/UI/Login?service=credentials');

casper.thenEvaluate(function(username, password) {
  document.querySelector('input[name="IDToken1"]').setAttribute('value', username);
  document.querySelector('input[name="IDToken2"]').setAttribute('value', password);
  document.querySelector('form[name="Login"]').submit();
}, username, password);

casper.thenOpen('https://dptservices.familysearch.org/portal', function() {
  this.click('div#login-button a');
});

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
