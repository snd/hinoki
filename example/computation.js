var hinoki = require('hinoki');

var factories = {
  count: function(xs) {
    return xs.length;
  },
  mean: function(xs, count) {
    var reducer = function(acc, x) {
      return acc + x;
    };
    return xs.reduce(reducer, 0) / count;
  },
  meanOfSquares: function(xs, count) {
    var reducer = function(acc, x) {
      return acc + x * x;
    };
    return xs.reduce(reducer, 0) / count;
  },
  variance: function(mean, meanOfSquares) {
    return meanOfSquares - mean * mean;
  }
};

var values = {
  xs: [1, 2, 3, 6]
};

var container = {
  factories: factories,
  values: values
};

hinoki(container, 'mean', console.log).then(function(mean) {
  console.log(mean);  // -> 3
});
