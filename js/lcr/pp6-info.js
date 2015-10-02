/**
 * Extracts data from LDS LCR Membership information.
 *
 * Expects to find pp6-info.json in this directory.
 */

var fs = require('fs');

var memberData = JSON.parse(fs.readFileSync('pp6-info.json'));
var families = memberData['families'];

var isOdd = function(n) {
  return n % 2 == 1;
}

var addressIsInWestQuorum = function(family) {
  var address = family['address']['streetAddress'];
  var northMatch = address.match(/(\d+)\s+N/);
  var north;
  if (northMatch) {
    north = northMatch[1];
  }

  var eastMatch = address.match(/(\d+)\s+E/);
  var east;
  if (eastMatch) {
    east = eastMatch[1];
  }

  if (east < 500) {
    return true;
  }

  if (east == 500 && isOdd(north)) {
    return true;
  }

  return false;
};

var headOfHouseholdIsElder = function(family) {
  var office = family['headOfHouse']['priesthoodOffice'];
  return office == 'ELDER';
};

var extractQuorumMembers = function(families) {
  quorumMembers = [];
  families.forEach(function(f) {
    if (headOfHouseholdIsElder(f) && addressIsInWestQuorum(f)) {
      quorumMembers.push(f);
    }
  });
  return quorumMembers;
};

var quorumMembers = extractQuorumMembers(families);

var emailList = quorumMembers.map(function(f) {
  var email = f['headOfHouse']['email'];
  if (email) {
    return email;
  }

  console.error('MEMBER WITHOUT EMAIL: ' + f['headOfHouse']['formattedName']);
});

emailList = emailList.join(',').replace(/,+/g, ',');

console.log('EMAILS: ' + emailList + '\n\n');

var addressList = quorumMembers.map(function(f) {
  return {
    name: f['formattedCoupleName'],
    address: f['address']['streetAddress']
  };
});

console.log('ADDRESSES:\n');
addressList.forEach(function(a) {
  console.log(a.address + ' - ' + a.name);
});
