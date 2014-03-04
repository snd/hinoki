# hinoki

[![Build Status](https://travis-ci.org/snd/hinoki.png)](https://travis-ci.org/snd/hinoki)

**magical inversion of control for nodejs**

hinoki can manage complexity in nodejs applications.

hinoki is a fairly complex piece of software

it is inspired by [prismatic's graph](https://github.com/Prismatic/plumbing#graph-the-functional-swiss-army-knife) and [angular's dependency injection](http://docs.angularjs.org/guide/di).

*Hinoki takes its name from the hinoki cypress, a tree that only grows in Japan and is the preferred wood for building palaces, temples and shrines.*

## WARNING

work in progress.

this is alpha software.
it is going to change a lot.
the documentation is incomplete.

use at your own risk.

---

- [introduction](#introduction)
- [install](#install)
- [events](#events)
- [contribution](#contribution)

### install

```
npm install hinoki
```

**or**

put this line in the dependencies section of your `package.json`:

```
"hinoki": "0.3.0-beta.3"
```

then run:

```
npm install
```

# the documentation below is work in progress!

# quick start

easy debugging

```javascript
container.emitter.on('any', console.log)
```

hinoki is currently used for the dependency injection part in a framework

### the hinoki model

just explain it in an introduction

hinoki can work with multiple containers

containers are asked in order

instances are added to the container that resolved the factory

a container manages names

an instance resolver is a function that takes a container and
an id and returns an instance.

programming against an interface.

wire up closures on the fly

### instances and factories and stuff

If a factory returns a thenable (bluebird or q promise) it will 

### containers

```javascript
var container = hinoki.newContainer();
```

a container has an event emitter

### instance resolver

```coffeescript
container.instanceResolvers = []
```

hinoki will emit various debug events through the emitter

you can subscribe to all by listening on the `any` event

or to specific events individually


### factory resolver

a resolver takes (resolves) an id and returns a factory

a resolver must be pure and always return the same factory or a factory
that behaves identically
of the same id

### container

the central data structure used in hinoki is a container.

a container is an object with the following properties:

#### factories

an object

#### instances

an object

#### 

#### underConstruction

#### emitter

see [events](#events) for more.

the container is a stateful object

### events

a container has an `emitter` property.
if no `emitter` property is set one is created
as soon as the first event would be emitted using `new require('events').EventEmitter()`.

errors are emitted as the `error` event.
`error` events are treated as a special case in node.
if there is no listener for it, then the default action is to print a stack
trace and exit the program.



#### instanceFound

emitted whenever an instance is requested and already found in the
`instances` property of a container

```javascript
{
    event: 'instanceFound'
    id: /* array of strings */,
    value: /* the instance that was created */,
    container: /* container */
}
```

#### instanceCreated

emitted whenever an instance is requested, was not found, the factory was called
returns an instance that is not a [thenable](http://promises-aplus.github.io/promises-spec/).

payload:

```javascript
{
    event: 'instanceCreated'
    id: /* array of strings */,
    value: /* the instance that was created */,
    container: /* container */
}
```

#### promiseCreated

#### promiseResolved



#### error

all errors are emitted as the `error` event.

##### cycle

##### missingFactory

##### exception

##### promiseRejected

##### factoryNotFunction

##### factoryReturnedUndefined

- `any` to listen 

### container internals

a container must have the following properties

- factoryResolvers
- instanceResolvers
- setInstance
- setUnderConstruction
- unsetUnderConstruction
- getUnderConstruction
- emit



### license: MIT
