/**
 * Extracts data from LDS LCR Membership information.
 *
 * Expects to find panish-highlands-3-info.json in this directory.
 */

var fs = require('fs');

var memberData = JSON.parse(fs.readFileSync('spanish-highlands-3-info.json'));
var families = memberData['families'];

var adultNames = [];
var youthNames = [];

families.forEach(function(f) {
  var headOfHouse = f['headOfHouse'];
  var spouse = f['spouse'];

  adultNames.push(headOfHouse['formattedName']);
  if (spouse !== null) {
    adultNames.push(spouse['formattedName']);
  }

  var children = f['children'];
  children.forEach(function(child) {
    var birthdate = child['birthdate'];

    var birthday = new Date(birthdate);
    var ageDifMs = Date.now() - birthday.getTime();
    var ageDate = new Date(ageDifMs); // miliseconds from epoch
    var ageInYears = Math.abs(ageDate.getUTCFullYear() - 1970);

    if (ageInYears >= 12) {
      youthNames.push(child['formattedName']);
    }
  });
});

// console.log('ADULT MEMBER LIST: (' + adultNames.length + ')\n');
// adultNames.forEach(function(name) {
//   console.log(name);
// });

console.log('YOUTH MEMBER LIST: (' + youthNames.length + ')\n');
youthNames.forEach(function(name) {
  console.log(name);
});
