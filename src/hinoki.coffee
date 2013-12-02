u = require './util'
f = require './factory'

{selectKeys, merge} = u

###################################################################################
# manual dependency injection

module.exports = h = {}

h.parseFunctionArguments = u.parseFunctionArguments

###################################################################################
# path

h.getKey = f.getKey()

h.getKeys = f.getKeys(
    selectKeys(u, 'arrayify')
)

h.idToString = f.idToString(
    selectKeys(h, 'getKeys')
)

h.addToId = f.addToId(
    selectKeys(u, 'arrayify')
)

h.isCyclic = f.isCyclic(
    merge(
        selectKeys(h, 'getKeys')
        selectKeys(u, 'arrayOfStringsHasDuplicates')
    )
)

###################################################################################
# container getters

h.getEmitter = f.getEmitter()

h.getInstance = f.getInstance(
    selectKeys(h, 'getKey')
)


h.getFactory = f.getFactory(
    selectKeys(h, 'getKey')
)

h.getDependencies = f.getDependencies(
    merge(
        selectKeys(u, 'parseFunctionArguments')
        selectKeys(h,
            'getKey'
            'getFactory'
        )
    )
)

###################################################################################
# finding instances

h.findContainerThatContainsFactory = f.findContainerThatContainsFactory(
    merge(
        selectKeys(u, 'find')
        selectKeys(h, 'getFactory')
    )
)

h.findContainerThatContainsInstance = f.findContainerThatContainsInstance(
    merge(
        selectKeys(u, 'find')
        selectKeys(h, 'getInstance')
    )
)

h.findInstance = f.findInstance(
    selectKeys(h, 'getInstance', 'findContainerThatContainsInstance')
)

# ###################################################################################
# # container setters

h.setInstance = f.setInstance(
    selectKeys(h, 'getKey')
)

h.cacheDependencies = f.cacheDependencies(
    selectKeys(h, 'getKey')
)

###################################################################################
# under construction

h.getUnderConstruction = f.getUnderConstruction(
    selectKeys(h, 'getKey')
)

h.addUnderConstruction = f.addUnderConstruction(
    selectKeys(h, 'getKey')
)

h.removeUnderConstruction = f.removeUnderConstruction(
    selectKeys(h, 'getKey')
)

# ###################################################################################
# # emit

h.emitInstanceCreated = f.emit(
    merge(
        {event: 'instanceCreated'}
        selectKeys(h, 'getEmitter')
    )
)

h.emitPromiseCreated = f.emit(
    merge(
        {event: 'promiseCreated'}
        selectKeys(h, 'getEmitter')
    )
)

h.emitPromiseResolved = f.emit(
    merge(
        {event: 'promiseResolved'}
        selectKeys(h, 'getEmitter')
    )
)

h.emitPromiseRejected = f.emit(
    merge(
        {event: 'promiseRejected'}
        selectKeys(h, 'getEmitter')
    )
)

h.emitInstanceFound = f.emit(
    merge(
        {event: 'instanceFound'}
        selectKeys(h, 'getEmitter')
    )
)

h.emitError = f.emit(
    merge(
        {event: 'error'}
        selectKeys(h, 'getEmitter')
    )
)

# ###################################################################################
# # error

h.cycleRejection = f.cycleRejection(
    selectKeys(h, 'idToString')
)
h.missingFactoryRejection = f.missingFactoryRejection(
    selectKeys(h, 'idToString', 'getKey')
)
h.exceptionRejection = f.exceptionRejection(
    selectKeys(h, 'getKey')
)
h.rejectionRejection = f.rejectionRejection(
    selectKeys(h, 'getKey')
)
h.factoryNotFunctionRejection = f.factoryNotFunctionRejection(
    selectKeys(h, 'getKey')
)

h.emitRejection = f.emitRejection(
    selectKeys(h, 'emitError')
)

# ###################################################################################
# # container side effecting functions

getOrCreateManyInstancesDelegate = ->
    if not h.getOrCreateManyInstances?
        h.getOrCreateManyInstances = f.getOrCreateManyInstances(
            selectKeys(h, 'getOrCreateInstance')
        )
    h.getOrCreateManyInstances.apply null, arguments

h.callFactory = f.callFactory(
    selectKeys(h,
        'getFactory'
        'missingFactoryRejection'
        'exceptionRejection'
        'emitInstanceCreated'
        'emitPromiseCreated'
        'emitPromiseResolved'
        'rejectionRejection'
    )
)

h.createInstance = f.createInstance(
    merge(
        selectKeys(h,
            'getDependencies'
            'getOrCreateManyInstances'
            'callFactory'
            'cacheDependencies'
            'addToId'
            'setInstance'
        )
        {getOrCreateManyInstances: getOrCreateManyInstancesDelegate}
    )
)

h.getOrCreateInstance = f.getOrCreateInstance(
    merge(
        selectKeys(u, 'startingWith')
        selectKeys(h,
            'findInstance'
            'emitInstanceFound'
            'isCyclic'
            'cycleRejection'
            'findContainerThatContainsFactory'
            'missingFactoryRejection'
            'getFactory'
            'factoryNotFunctionRejection'
            'getUnderConstruction'
            'addUnderConstruction'
            'removeUnderConstruction'
            'createInstance'
        )
    )
)

###################################################################################
# interface

h._inject = f._inject(
    merge(
        selectKeys(h, 'emitRejection')
        {getOrCreateManyInstances: getOrCreateManyInstancesDelegate}
    )
)

h.inject = f.inject(
    merge(
        selectKeys(u, 'arrayify', 'parseFunctionArguments')
        selectKeys(h, '_inject')
    )
)
