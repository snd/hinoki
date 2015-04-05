var Promise = require('bluebird');

var dns = Promise.promisifyAll(require('dns'));

var hinoki = require('hinoki');

var factories = {
  addresses: function(domain) {
    return dns.resolve4Async(domain);
  },
  domains: function(addresses) {
    return Promise.map(addresses, function(address) {
      return dns.reverseAsync(address);
    });
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
