# hinoki

[![Build Status](https://travis-ci.org/snd/hinoki.png)](https://travis-ci.org/snd/hinoki)

**magical inversion of control for nodejs**

hinoki can manage complexity in nodejs applications.

it is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

## get started

### install

```
npm install hinoki
```

**or**

put this line in the dependencies section of your `package.json`:

```
"hinoki": "0.1.0"
```

then run:

```
npm install
```

### require

```javascript
var hinoki = require('hinoki');
```

### lets make a graph

```javascript
var graph = {
    a: function() {
        return 1;
    },
    b: function(a) {
        return a + 1;
    },
    c: function(a, b) {
        return a + b;
    }
};
```

`a`, `b` and `c` are the **nodes** of the graph.

every node has a **factory** function:
node `a` has the factory `function() {return 1;}`.

the arguments of a factory are the **dependencies** of the node:
- `a` has no dependencies.
- `b` depends on `a`.
- `c` depends on `a` and `b`.

a factory returns the **instance** of a node.
it must be called with the instances of its dependencies:
`function(a) {return a + 1;}` must be called with the instance of `a`.

### lets make a container

we need a place to put those instances:
lets call it `instances`.

the pair of `factories` and `instances` is called a **container**. let's make one:

```javascript
var container = {
    factories: graph,
    instances: {}
};
```

if you omit the `instances` property hinoki will create one for you.

### let's ask the container for an instance

```javascript
hinoki.inject(container, function(c) {
    console.log(c); // => 3
});
```

because we asked for `c`, which depends on `a` and `b`, hinoki has
made instances for `a` and `b` as well and added them to the `instances` property:

```javascript
console.log(container.instances.a); // => 1
console.log(container.instances.b); // => 2
console.log(container.instances.c); // => 3
```

**hinoki will add all instances to the instances property.**

while `a` is a dependency of both `b` and `c`, the factory for `a` was only
called once. the second time `a` was needed it already had an instance.

**hinoki will only call the factory function for nodes that you ask for (or that the nodes you ask for depend on) and that have no instance yet.**

lets provide an instance directly:

```javascript
var container = {
    factories: graph,
    instances: {
        a: 3
    }
};

hinoki.inject(container, function(a, b) {
    console.log(a) // => 3
    console.log(b) // => 4
});
```

the factory for `a` wasn't called since we already provided an instance for `a`.

we only asked for `a` and `b`. it was not necessary to get the instance for `c`:

```javascript
console.log(container.instances.a) // => 1
console.log(container.instances.b) // => 2
console.log(container.instances.c) // => undefined
```

### promises

if a factory returns a [q promise](https://github.com/kriskowal/q)
hinoki will wait until the promise is resolved.

this can greatly simplify complex async flows.

see [example/async.js](example/async.js).

### hooks

hooks let you change the error handling of any container.
you can also use them to add debugging to a container.

let's log every time a promise is returned from a factory:

```javascript
var container = {
    hooks: {
        promise: function(chain, promise) {
            console.log('factory for service ' + chain[id] + ' returned promise' + promise);
        };
    }
};
```

look at [src/hooks.coffee](src/hooks.coffee) for all available hooks
and their default implementations.

## great! can i do anything useful with it?

### you can automate dependency injection

see [example/dependency-injection](example/dependency-injection):

[example/dependency-injection/load-sync.js](example/dependency-injection/load-sync.js)
is used by [example/dependency-injection/inject.js](example/dependency-injection/inject.js)
to pull in all the properties of the exports in the files in
[example/dependency-injection/factory](example/dependency-injection/factory).
hinoki then uses the graph of all those properties.
this enables inversion of control for all files in
[example/dependency-injection/factory](example/dependency-injection/factory).

**expect more documentation on this soon!**

### you can tame async flows

see [example/async.js](example/async.js)

### you can structure computation

see [example/computation.js](example/computation.js)

### license: MIT
