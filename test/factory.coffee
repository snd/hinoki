factory = require '../src/factory'

Promise = require 'bluebird'

module.exports =

###################################################################################
# functions that inject into a factory function

    'inject':

        'containers and callback': (test) ->
            test.expect 5

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            arrayify = (arg1) ->
                test.equals arg1, container
                return containers

            parseFunctionArguments = (arg1) ->
                test.equals arg1, cb
                return dependencyIds

            _inject = (arg1, arg2, arg3) ->
                test.equals arg1, containers
                test.equals arg2, dependencyIds
                test.equals arg3, cb

            inject = factory.inject(
                arrayify
                parseFunctionArguments
                _inject
            )

            inject container, cb

            test.done()

        'containers, dependencyIds and callback': (test) ->
            test.expect 4

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            arrayify = (arg1) ->
                test.equals arg1, container
                return containers
            parseFunctionArguments = ->
                test.fail()
            _inject = (arg1, arg2, arg3) ->
                test.equals arg1, containers
                test.equals arg2, dependencyIds
                test.equals arg3, cb

            inject = factory.inject(
                arrayify
                parseFunctionArguments
                _inject
            )

            inject container, dependencyIds, cb

            test.done()

        '2 or 3 arguments required': (test) ->
            test.expect 2

            arrayify = ->
                test.fail()
            parseFunctionArguments = ->
                test.fail()
            _inject = ->
                test.fail()

            inject = factory.inject(
                arrayify
                parseFunctionArguments
                _inject
            )

            try
                inject()
            catch err
                test.equals err.message, '2 or 3 arguments required but 0 were given'

            try
                inject 1, 2, 3, 4
            catch err
                test.equals err.message, '2 or 3 arguments required but 4 were given'

            test.done()

        'at least 1 container required': (test) ->
            test.expect 1

            arrayify = ->
                return []
            parseFunctionArguments = ->
                test.fail()
            _inject = ->
                test.fail()

            inject = factory.inject(
                arrayify
                parseFunctionArguments
                _inject
            )

            try
                inject {}, 2
            catch err
                test.equals err.message, 'at least 1 container is required'
                test.done()

        'cb must be a function': (test) ->
            test.expect 2

            arrayify = ->
                return [{}]
            parseFunctionArguments = ->
                test.fail()
            _inject = ->
                test.fail()

            inject = factory.inject(
                arrayify
                parseFunctionArguments
                _inject
            )

            try
                inject {}, 2
            catch err
                test.equals err.message, 'cb must be a function'

            try
                inject {}, [], 2
            catch err
                test.equals err.message, 'cb must be a function'

            test.done()

    '_inject':

        'success': (test) ->
            test.expect 3

            containers = {}
            ids = {}
            instances = [{}, {}, {}]

            getOrCreateManyInstances = (arg1, arg2) ->
                test.equals arg1, containers
                test.equals arg2, ids
                return Promise.resolve instances

            _inject = factory._inject(
                getOrCreateManyInstances
            )

            _inject containers, ids, (args...) ->
                test.deepEqual args, instances
                test.done()

        'error': (test) ->
            test.expect 4

            containers = {}
            ids = {}
            rejection =
                container:
                    emit: (arg1, arg2) ->
                        test.equal arg1, rejection.container
                        test.equal arg2, rejection
                        test.done()

            getOrCreateManyInstances = (arg1, arg2) ->
                test.equal arg1, containers
                test.equal arg2, ids
                return Promise.reject rejection

            _inject = factory._inject(
                getOrCreateManyInstances
            )

            _inject containers, ids, (args...) ->
                test.fail()

###################################################################################
# functions that return promises

    'getOrCreateInstance':

        'instanceResolved': (test) ->
            test.expect 8

            fail = -> test.fail()

            containers = []
            id = {}
            instanceResult =
                instance: {}
                resolver: {}
                container:
                    emit: (container, event) ->
                        test.equals event.event, 'instanceResolved'
                        test.equals event.id, id
                        test.equals event.instance, instanceResult.instance
                        test.equals event.resolver, instanceResult.resolver
                        test.equals event.container, instanceResult.container

            findContainerThatCanResolveInstance = (arg1, arg2) ->
                test.equal arg1, containers
                test.equal arg2, id
                instanceResult

            getOrCreateInstance = factory.getOrCreateInstance(
                Promise
                fail # getIdsToInject
                fail # addToId
                fail # getOrCreateManyInstances
                findContainerThatCanResolveInstance
                fail # isCyclic
                fail # isUndefined
                fail # cycleRejection
                fail # findContainerThatCanResolveFactory
                fail # unresolvableFactoryRejection
                fail # factoryNotFunctionRejection
                fail # startingWith
                fail # isThenable
                fail # getKey
            )

            getOrCreateInstance(containers, id).then (result) ->
                test.equals result, instanceResult.instance
                test.done()
