var Promise = require('bluebird');

var hinoki = require('../lib/hinoki');

module.exports = {
  'readme example': function(test) {
    var factories = {
      sumFn: function() {
        return function(xs) {
          return xs.reduce(function(acc, x) { return acc + x; }, 0);
        }
      },
      numbersSquared: function(numbers) {
        return numbers.map(function(x) { return x * x; });
      },
      numbersSorted: function(numbers) {
        return numbers.slice().sort(function(a, b) { return a - b; });
      },
      count: function(numbers) {
        return numbers.length;
      },
      median: function(numbersSorted, count) {
        return numbersSorted[Math.round(count / 2)];
      },
      mean: function(numbers, count, sumFn) {
        return sumFn(numbers) / count;
      },
      meanOfSquares: function(numbersSquared, count, sumFn) {
        return sumFn(numbersSquared) / count;
      },
      variance: function(mean, meanOfSquares) {
        return meanOfSquares - mean * mean;
      }
    };

    var lifetime = {
      factories: factories,
      values: {
        // TODO shuffle this around
        numbers: [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
      }
    };

    hinoki(lifetime, 'mean')
      .then(function(mean) {
        test.equal(mean, 8.8);
        return hinoki(lifetime, ['mean', 'variance', 'numbersSorted']);
      })
      .spread(function(mean, variance, numbersSorted) {
        console.log('mean', mean); // ->
        console.log('variance', variance); // ->
        console.log('numbersSorted', numbersSorted); // ->
        return hinoki(lifetime, function(variance, median) {
          console.log('variance', variance); // ->
          console.log('median', median); // ->
        });
      })
      .then(function() {
        test.done();
      });
  }
};
