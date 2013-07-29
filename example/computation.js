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

var container = {
    factories: factories,
    instances: {
        xs: [1, 2, 3, 6]
    }
};

hinoki.inject(container, function(mean) {
    console.log(mean);  // -> 3
});
