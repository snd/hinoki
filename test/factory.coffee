factory = require '../src/factory'

Promise = require 'bluebird'

module.exports =

###################################################################################
# interface

    'inject':

        'containers and callback': (test) ->
            test.expect 5

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            inject = factory.inject
                arrayify: (arg1) ->
                    test.equals arg1, container
                    return containers
                parseFunctionArguments: (arg1) ->
                    test.equals arg1, cb
                    return dependencyIds
                _inject: (arg1, arg2, arg3) ->
                    test.equals arg1, containers
                    test.equals arg2, dependencyIds
                    test.equals arg3, cb

            inject container, cb

            test.done()

        'containers, dependencyIds and callback': (test) ->
            test.expect 4

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            inject = factory.inject
                arrayify: (arg1) ->
                    test.equals arg1, container
                    return containers
                parseFunctionArguments: ->
                    test.fail()
                _inject: (arg1, arg2, arg3) ->
                    test.equals arg1, containers
                    test.equals arg2, dependencyIds
                    test.equals arg3, cb


            inject container, dependencyIds, cb

            test.done()

        '2 or 3 arguments required': (test) ->
            test.expect 2

            inject = factory.inject
                arrayify: ->
                    test.fail()
                parseFunctionArguments: ->
                    test.fail()
                _inject: ->
                    test.fail()

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

            inject = factory.inject
                arrayify: ->
                    return []
                parseFunctionArguments: ->
                    test.fail()
                _inject: ->
                    test.fail()

            try
                inject {}, 2
            catch err
                test.equals err.message, 'at least 1 container is required'
                test.done()

        'cb must be a function': (test) ->
            test.expect 2

            inject = factory.inject
                arrayify: ->
                    return [{}]
                parseFunctionArguments: ->
                    test.fail()
                _inject: ->
                    test.fail()

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

            _inject = factory._inject
                getOrCreateManyInstances: (arg1, arg2) ->
                    test.equals arg1, containers
                    test.equals arg2, ids
                    return Promise.resolve instances
                emitRejection: (arg1) ->
                    test.fail()

            _inject containers, ids, (args...) ->
                test.deepEqual args, instances
                test.done()

        'error': (test) ->
            test.expect 3

            containers = {}
            ids = {}
            rejection = Promise.reject {}

            _inject = factory._inject
                getOrCreateManyInstances: (arg1, arg2) ->
                    test.equal arg1, containers
                    test.equal arg2, ids
                    return Promise.reject rejection
                emitRejection: (arg1) ->
                    test.equal arg1, rejection
                    test.done()

            _inject containers, ids, (args...) ->
                test.fail()

    # 'callFactory':

    #     'emit and return instance if one is created': (test) ->
    #         test.expect 8

    #         instance = {}
    #         container = {}
    #         id = {}

    #         deps =
    #             getFactory: (arg1, arg2) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 return (arg1, arg2) ->
    #                     test.equals arg1, 1
    #                     test.equals arg2, 2
    #                     return instance
    #             emitInstanceCreated: (arg1, arg2, arg3) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, instance

    #         callFactory = factory.callFactory deps

    #         promise = callFactory container, id, Q.resolve [1, 2]

    #         promise.then (value) ->
    #             test.equals value, instance
    #             test.done()

    #     'return rejection if factory is not found': (test) ->
    #         test.expect 5

    #         container = {}
    #         rejection = {}
    #         id = {}

    #         deps =
    #             getFactory: (arg1, arg2) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 return null
    #             missingFactoryRejection: (arg1, arg2) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 return Q.reject rejection

    #         callFactory = factory.callFactory deps

    #         promise = callFactory container, id, Q.resolve [1, 2]

    #         promise.fail (value) ->
    #             test.equals value, rejection
    #             test.done()

    #     'return rejection if factory throws exception': (test) ->
    #         test.expect 4

    #         container = {}
    #         rejection = {}
    #         id = {}
    #         err = {}

    #         deps =
    #             getFactory: ->
    #                 return ->
    #                     throw err
    #             exceptionRejection: (arg1, arg2, arg3, arg4) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, err
    #                 return Q.reject rejection

    #         callFactory = factory.callFactory deps

    #         promise = callFactory container, id, [1, 2]

    #         promise.fail (value) ->
    #             test.equals value, rejection
    #             test.done()

    #     'emit and return promise when it is created': (test) ->
    #         test.expect 7

    #         container = {}
    #         resolution = {}
    #         promiseReturnedByFactory = Q.resolve resolution
    #         id = {}

    #         deps =
    #             getFactory: ->
    #                 ->
    #                     promiseReturnedByFactory
    #             emitPromiseCreated: (arg1, arg2, arg3) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, promiseReturnedByFactory
    #             emitPromiseResolved: (arg1, arg2, arg3) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, resolution

    #         callFactory = factory.callFactory deps

    #         promise = callFactory container, id, Q.resolve [1, 2]

    #         promise.then (value) ->
    #             test.equals value, resolution
    #             test.done()

    #     'return rejection if promise is rejected': (test) ->
    #         test.expect 7

    #         container = {}
    #         rejection = {}
    #         promiseReturnedByFactory = Q.reject rejection
    #         rejectionRejection = {}
    #         id = {}

    #         deps =
    #             getFactory: ->
    #                 ->
    #                     promiseReturnedByFactory
    #             emitPromiseCreated: (arg1, arg2, arg3) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, promiseReturnedByFactory
    #             rejectionRejection: (arg1, arg2, arg3) ->
    #                 test.equals arg1, container
    #                 test.equals arg2, id
    #                 test.equals arg3, rejection
    #                 return Q.reject rejectionRejection

    #         callFactory = factory.callFactory deps

    #         promise = callFactory container, id, Q.resolve [1, 2]

    #         promise.fail (value) ->
    #             test.equals value, rejectionRejection
    #             test.done()

    # 'setInstance':

    #     'success': (test) ->
    #         test.expect 3
    #         container = {}
    #         id = {}
    #         deps =
    #             getKey: (arg1) ->
    #                 test.equals arg1, id
    #                 return 'a'
    #         setInstance = factory.setInstance deps
    #         promise = setInstance container, id, Q(5)

    #         promise.then (value) ->
    #             test.equals value, 5
    #             test.equals container.instances.a, 5
    #             test.done()

    #     'error': (test) ->
    #         test.expect 2
    #         container = {}
    #         id = {}
    #         deps =
    #             getKey: ->
    #                 test.fail()
    #         setInstance = factory.setInstance deps
    #         promise = setInstance container, id, Q.reject(5)

    #         promise.fail (value) ->
    #             test.equals value, 5
    #             test.ok not container.instances?
    #             test.done()

    # 'setDependencies':

    #     'success': (test) ->
    #         test.expect 3
    #         container = {}
    #         id = {}
    #         deps =
    #             getKey: (arg1) ->
    #                 test.equals arg1, id
    #                 return 'a'
    #         setDependencies = factory.setDependencies deps
    #         promise = setDependencies container, id, Q(5)

    #         promise.then (value) ->
    #             test.equals value, 5
    #             test.equals container.dependencies.a, 5
    #             test.done()

    #     'error': (test) ->
    #         test.expect 2
    #         container = {}
    #         id = {}
    #         deps =
    #             getKey: ->
    #                 test.fail()
    #         setDependencies = factory.setDependencies deps
    #         promise = setDependencies container, id, Q.reject(5)

    #         promise.fail (value) ->
    #             test.equals value, 5
    #             test.ok not container.dependencies?
    #             test.done()

