u = require './util'
f = require './factory'

{selectKeys, merge} = u

###################################################################################
# manual dependency injection

module.exports = h = {}

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
        selectKeys(u, 'arrayOfStringsHasDuplicate')
    )
)

###################################################################################
# container getters

h.getEmitter = f.getEmitter()

h.getInstance = f.getInstance(
    selectKeys(h, 'getKeys')
)


h.getFactory = f.getFactory(
    selectKeys(h, 'getKeys')
)

h.getDependencies = f.getDependencies(
    merge(
        selectKeys(u, 'parseFunctionArguments')
        selectKeys(h,
            'getKeys'
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

h.findInstance = f.findInstance(
    merge(
        selectKeys(u, 'find')
        selectKeys(h, 'getInstance')
    )
)

# ###################################################################################
# # container setters

h.setInstance = f.setInstance(
    selectKeys(h, 'getKey')
)

h.setDependencies = f.setDependencies(
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

h.emit = f.emit(
    merge(
        {event: 'error'}
        selectKeys(h, 'getEmitter')
    )
)

# ###################################################################################
# # error

h.cycleRejection(
    selectKeys(h, 'idToString')
)
h.missingFactoryRejection(
    selectKeys(h, 'idToString', 'getKey')
)
h.exceptionRejection(
    selectKeys(h, 'getKey')
)
h.rejectionRejection(
    selectKeys(h, 'getKey')
)
h.factoryNotFunctionRejection(
    selectKeys(h, 'getKey')
)

h.emitRejection = f.emit(
    selectKeys(h, 'emit')
)

# ###################################################################################
# # container side effecting functions
# 
# h.callFactory = f.callFactory(
#     h.getFactory
#     h.emitInstanceCreated
#     h.emitPromiseCreated
#     h.emitPromiseResolved
#     h.emitPromiseRejected
#     h.missingFactoryRejection
#     h.exceptionRejection
#     h.rejectionRejection
# )
# 
# h.getOrCreateInstance = f.getOrCreateInstance(
#     u.startingWith
#     h.getInstance
#     h.findInstance
#     h.findContainerThatContainsFactory
# 
# )
# 
# h.getOrCreateManyInstances = f.getOrCreateManyInstances(
#     h.getOrCreateInstance
# )
# 
# ###################################################################################
# # interface
# 
# h._inject = f._inject({
#     selectKeys(h, 'getOrCreateManyInstances'
#     h.getOrCreateManyInstances
#     h.emitRejection
# )
# 
# h.inject = f.inject(
#     u.arrayify
#     u.parseFunctionArguments
#     h._inject
# )
