var hinoki = require('hinoki');

var factories = {
  a: function() { return 'a'; },
  b: function() { return 'b'; },
  c: function() { return 'c'; },
  d: function() { return 'd'; },
  // this should depend on ['a', 'c'], we override this below
  ac: function(a, b) { return a + b; },
  acd: function(ac, d) { return ac + d; }
};

factories.ac.$inject = ['a', 'c'];

var lifetime = {
  factories: factories
};

hinoki(lifetime, 'acd', console.log).then(function(acd) {
  console.log(acd);  // -> 'acd'
  // dependency ids have been cached
  console.log(factories.a.$inject); // -> []
  console.log(factories.acd.$inject); // -> ['ac', 'd']
});
