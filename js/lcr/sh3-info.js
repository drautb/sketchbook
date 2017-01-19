/**
 * Extracts data from LDS LCR Membership information.
 *
 * Expects to find panish-highlands-3-info.json in this directory.
 */

var fs = require('fs');

var memberData = JSON.parse(fs.readFileSync('spanish-highlands-3-info.json'));
var families = memberData['families'];

var names = [];

families.forEach(function(f) {
  var headOfHouse = f['headOfHouse'];
  var spouse = f['spouse'];

  names.push(headOfHouse['formattedName']);
  if (spouse !== null) {
    names.push(spouse['formattedName']);
  }
});

console.log('ADULT MEMBER LIST: (' + names.length + ')\n');
names.forEach(function(name) {
  console.log(name);
});
