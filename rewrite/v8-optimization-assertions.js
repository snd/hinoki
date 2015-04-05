#!/usr/bin/env node --trace_opt --trace_deopt --trace_inlining --allow-natives-syntax
'use strict';

var assert = require('assert');
var _ = require('lodash');
var hinoki = require('./hinoki');
var process = require('process');

var ITERATIONS = 2000;
var OPTIMIZED = 1;
var NOT_OPTIMIZED = 2;

////////////////////////////////////////////////////////////////////////////////
// helpers

function statusToString(status) {
  switch(status) {
    case 1: return 'optimized';
    case 2: return 'not optimized';
    case 3: return 'always optimized';
    case 4: return 'never optimized';
    case 6: return 'maybe deoptimized';
  }
}

function optimize(func, args) {
  func.apply(null, args);
  %OptimizeFunctionOnNextCall(func);
  func.apply(null, args);
  return func;
}

function assertOptimized(func) {
  var status = %GetOptimizationStatus(func);
  assert.equal(OPTIMIZED, status, %FunctionGetName(func) + ': ' + statusToString(status));
}

function assertNotOptimized(func) {
  var status = %GetOptimizationStatus(func);
  assert.equal(NOT_OPTIMIZED, status, %FunctionGetName(func) + ': ' + statusToString(status));
}

function assertOptimizable(func, args) {
  optimize(func, args);
  assertOptimized(func);
}

function assertNotOptimizable(func) {
  optimize(func);
  assertNotOptimized(func);
}

function diffToNs(diff) {
  return diff[0] * 1e9 + diff[1];
}

function nsToS(ns) {
  return ns / 1e9;
}

function nsToMs(ns) {
  return ns / 1e6;
}

function benchmark(func, getArgs) {
  // measurements
  var ms = {
    name: %FunctionGetName(func),
    iterations: ITERATIONS,
    firstOptAt: null,
    optCount: 0,
    firstDeoptAt: null,
    deoptCount: 0,
    minNs: null,
    maxNs: null,
    sumNs: 0
  };

  console.log('')
  console.log('START ' + ms.name);
  console.log('')
  console.time('END ' + ms.name);

  for (var i = 0; i < ITERATIONS; i++) {
    var args = getArgs();
    var statusBefore = %GetOptimizationStatus(func);

    // BEGIN
    var time = process.hrtime();
    func.apply(null, args);
    var elapsed = diffToNs(process.hrtime(time));
    // END

    if (!ms.minNs) ms.minNs = elapsed;
    if (!ms.maxNs) ms.maxNs = elapsed;
    ms.maxNs = Math.max(ms.maxNs, elapsed);
    ms.minNs = Math.min(ms.minNs, elapsed);
    ms.sumNs += elapsed;

    var statusAfter = %GetOptimizationStatus(func);
    if (statusBefore != OPTIMIZED && statusAfter == OPTIMIZED) {
      // OPT :)
      if (!ms.firstOptAt) ms.firstOptAt = i;
      ms.optCount++;
    } else if (statusBefore != NOT_OPTIMIZED && statusAfter == NOT_OPTIMIZED) {
      // DEOPT :(
      if (!ms.firstDeoptAt) ms.firstDeoptAt = i;
      ms.deoptCount++;
    }

  }

  console.log('')
  console.timeEnd('END ' + ms.name);
  console.log('')

  ms.sumMs = nsToMs(ms.sumNs);
  ms.sumS = nsToS(ms.sumNs);
  ms.avgNs = ms.sumNs / ITERATIONS;
  ms.opsPerSec = ITERATIONS / ms.sumS;
  ms.finalState = statusToString(%GetOptimizationStatus(func));
  return ms;
}

////////////////////////////////////////////////////////////////////////////////
// assertions
// check that V8s crankshaft naturally (on its own) optimizes all functions
// these so far are insanely fast

// isObjectLike

var measurements = benchmark(
  hinoki.isObjectLike,
  function() {
    var choices = [{}, 1, 3.5, 'foo', function() {}];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.isObjectLike);

// isPromise

var measurements = benchmark(
  hinoki.isPromise,
  function() {
    var choices = [{}, 1, 'foo', {then: 6}, {then: function() {}}];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.isPromise);

// isError

var measurements = benchmark(
  hinoki.isError,
  function() {
    var choices = [new Error('error'), 1, 'foo', {then: function() {}}];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.isError);

// parseFunctionArguments

var measurements = benchmark(
  hinoki.parseFunctionArguments,
  function() {
    var choices = [
      function(a) {},
      function(a, b) {},
      function(a, b, c) {},
      function(a, b, c, d) {},
      function(a, b, c, d, e) {},
      function(a, b, c, d, e, f) {}
    ]
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.parseFunctionArguments);

// getDependencies

var measurements = benchmark(
  hinoki.getDependencies,
  function() {
    var choices = [
      function(a) {},
      function(a, b) {},
      function(a, b, c) {},
      function(a, b, c, d) {},
      function(a, b, c, d, e) {},
      function(a, b, c, d, e, f) {}
    ];
    choices[0].$inject = ['x', 'y', 'z'];
    choices[2].$inject = [];
    choices[4].$inject = ['y', 'z'];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.getDependencies);
assertOptimized(hinoki.parseFunctionArguments);
assertOptimized(_.isArray);

// getDependenciesCached

var measurements = benchmark(
  hinoki.getDependenciesCached,
  function() {
    var choices = [
      function(a) {},
      function(a, b) {},
      function(a, b, c) {},
      function(a, b, c, d) {},
      function(a, b, c, d, e) {},
      function(a, b, c, d, e, f) {}
    ];
    choices[0].$inject = ['x', 'y', 'z'];
    choices[2].$inject = [];
    choices[4].$inject = ['y', 'z'];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.getDependenciesCached);
assertOptimized(hinoki.parseFunctionArguments);
assertOptimized(_.isArray);

// arrayOfStringsHasDuplicates

var measurements = benchmark(
  hinoki.arrayOfStringsHasDuplicates,
  function() {
    var choices = [
      ['a', 'b', 'c', 'd', 'e'],
      ['a', 'b', 'a', 'a', 'e'],
      ['c', 'd', 'e'],
      ['c', 'c', 'e'],
      ['e', 'b', 'c', 'd', 'e']
    ];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.arrayOfStringsHasDuplicates);
assertOptimized(_.has);

// defaultResolver

var measurements = benchmark(
  hinoki.defaultResolver,
  function() {
    var nameChoices = ['a', 'b', 'c'];
    var containerChoices = [
      {},
      {values: {}},
      {values: {a: 5}},
      {factories: {}, values: {}},
      {factories: {b: function() {}}, values: {}},
      {factories: {a: function() {}}},
      {}
    ];
    return [_.sample(nameChoices), _.sample(containerChoices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.defaultResolver);
// TODO make these optimized
// defaultResolver seems to break all the optimization
// assertOptimized(hinoki.isObjectLike);
// assertOptimized(_.isFunction);
// assertOptimized(_.isUndefined);
// assertOptimized(hinoki.getDependenciesCached);
// assertOptimized(hinoki.ValueResult);
// assertOptimized(hinoki.FactoryResult);


// assertOptimizable(_.isFunction, function() {});
// assertOptimizable(hinoki.defaultResolver, ['a', {}]);

// coerceIntoArray

var measurements = benchmark(
  hinoki.coerceIntoArray,
  function() {
    var choices = [
      null,
      undefined,
      1,
      'foo',
      [],
      [1],
      ['foo', 1, 1]
    ];
    return [_.sample(choices)];
  }
);
console.log(measurements);
assertOptimized(hinoki.coerceIntoArray);
assertOptimized(_.isArray);

// notOptimizable

function notOptimizable() {
  try {
    return 1 + 7;
  } catch (e) {
    return 8;
  }
}
assertNotOptimizable(notOptimizable);

////////////////////////////////////////////////////////////////////////////////
// other assertions
// assert.ok(hinoki.isError(new hinoki

console.log('OK');
