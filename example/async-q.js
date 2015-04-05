var dns = require('dns');

var q = require('q');
var hinoki = require('hinoki');

var factories = {
  addresses: function(domain) {
    return q.nfcall(dns.resolve4, domain);
  },
  domains: function(addresses) {
    return q.all(addresses.map(function(address) {
      return q.nfcall(dns.reverse, address);
    }));
  }
};

var values = {
  domain: 'google.com'
};

var lifetime = {
  factories: factories,
  values: values
};

hinoki(lifetime, 'domains', console.log).then(function(domains) {
  console.log(domains);
});
