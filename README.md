# hinoki

magical inversion of control for nodejs.

crafted with great care.

### definitions

**service** -

**id** - a string that uniquely identifies a service

**dependency** - 

**instance** -

**factory** - a function which takes **dependencies** as arguments and returns an **instance** (that implements a service)

**factories** - 

**scope** - an object with properties where a key that is an *id* is associated  with an **instance** of that service.
*used for the*

**seed** - an instance in without a corresponding factory

*used for bootstrapping and testing*

**container** manages services, factories, scope, configuration, lifetime

**lifetime**

### basic usage

```javascript
var hinoki = require('hinoki');

var factories = {
    a: function() {
        return 1;
    },
    b: function(a) {
        return a + 1;
    },
    c: function(a, b) {
        return a + b + 1;
    }
};

var container = {
    factories: factories,
    scope: {},
    config: {}
};

hinoki.inject(container, function(a, b, c) {
    console.log(a);     // -> 1
    console.log(b);     // -> 2
    console.log(c);     // -> 3
});
```

### hooks

provide all the necessary context

default behaviour is implemented using hooks. you can overwrite default behaviour.

error handling is per container

mainly used for debugging

```javascript
config.onError = function(id, factory, err) {
    throw new Error('hinoki: error instantiating service ' + id + ': ' + err.message);
};

config.onCircular = function(circularIds) {
    throw new Error('hinoki: circular dependency ' + circularIds.join(' <- '));
};

// when a new instance needs to be created
config.onRequire = function(id, factory, requiringId, requiringFactory) {

};

// when an instance was created and is ready to be set on the scope
config.onRegister = function(id, scope, instance) {
    scope[id] = instance;
};

config.onInject = function(id, factory, instances) {
    factory.apply(undefined, instances);
};

config.onNotFound = function(id, parent) {
    if (!parentContainer) throw new Error('hinoki: not found ' + id);
};
```

### multiple containers

```javascript
hinoki.inject([c1, c2, c3], function(a, b, c) {

});
```

the dependencies are looked up right to left (nearest to farest from factory)

decreasing lifetime

### async

If a Factory returns a promise hinoki will wait until the promise Is resolved

can also be used to make complex async flows more managable

use `q.nfcall` for callback style functions

```javascript
factories.async = function() {
    q.nfcall();
};
```

# license: MIT
