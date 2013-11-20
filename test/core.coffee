core = require '../src/core'

Q = require 'q'

module.exports =

    'setInstance':

        'success': (test) ->
            test.expect 3
            container = {}
            id = {}
            getKey = (arg1) ->
                test.equals arg1, id
                return 'a'
            setInstance = core.setInstance getKey
            promise = setInstance container, id, Q(5)

            promise.then (value) ->
                test.equals value, 5
                test.equals container.instances.a, 5
                test.done()

        'error': (test) ->
            test.expect 2
            container = {}
            id = {}
            getKey = ->
                test.fail()
            setInstance = core.setInstance getKey
            promise = setInstance container, id, Q.reject(5)

            promise.fail (value) ->
                test.equals value, 5
                test.ok not container.instances?
                test.done()

    'setDependencies':

        'success': (test) ->
            test.expect 3
            container = {}
            id = {}
            getKey = (arg1) ->
                test.equals arg1, id
                return 'a'
            setDependencies = core.setDependencies getKey
            promise = setDependencies container, id, Q(5)

            promise.then (value) ->
                test.equals value, 5
                test.equals container.dependencies.a, 5
                test.done()

        'error': (test) ->
            test.expect 2
            container = {}
            id = {}
            getKey = ->
                test.fail()
            setDependencies = core.setDependencies getKey
            promise = setDependencies container, id, Q.reject(5)

            promise.fail (value) ->
                test.equals value, 5
                test.ok not container.dependencies?
                test.done()

    'callFactory':

        'factory returns instance': (test) ->
            test.expect 7

            instance = {}
            container = {}
            id = {}

            dependencies =
                getFactory: (arg1, arg2) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    return (arg1, arg2) ->
                        test.equals arg1, 1
                        test.equals arg2, 2
                        return instance
                emitInstance: (arg1, arg2, arg3) ->
                    test.equals arg1, container
                    test.equals arg2, id

            callFactory = core.callFactory dependencies

            promise = callFactory container, id, Q.resolve [1, 2]

            promise.then (value) ->
                test.equals value, instance
                test.done()

        'factory not found': (test) ->
            test.expect 3

            container = {}
            rejection = {}
            id = {}

            dependencies =
                getFactory: ->
                    return null
                factoryNotFoundRejection: (arg1, arg2) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    return rejection

            callFactory = core.callFactory dependencies

            promise = callFactory container, id, Q.resolve [1, 2]

            promise.fail (value) ->
                test.equals value, rejection
                test.done()

        'factory throws exception': (test) ->
            test.expect 4

            container = {}
            rejection = {}
            id = {}
            err = {}

            dependencies =
                getFactory: ->
                    return ->
                        throw err
                exceptionRejection: (arg1, arg2, arg3, arg4) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    test.equals arg3, err
                    return rejection

            callFactory = core.callFactory dependencies

            promise = callFactory container, id, Q.resolve [1, 2]

            promise.fail (value) ->
                test.equals value, rejection
                test.done()

        'factory returns promise which is resolved to an instance': (test) ->
            test.expect 7

            container = {}
            resolution = {}
            promiseReturnedByFactory = Q.resolve resolution
            id = {}

            dependencies =
                getFactory: ->
                    ->
                        promiseReturnedByFactory
                emitPromise: (arg1, arg2, arg3) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    test.equals arg3, promiseReturnedByFactory
                emitResolved: (arg1, arg2, arg3) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    test.equals arg3, resolution

            callFactory = core.callFactory dependencies

            promise = callFactory container, id, Q.resolve [1, 2]

            promise.then (value) ->
                test.equals value, resolution
                test.done()

        'factory returns promise which is rejected': (test) ->
            test.expect 7

            container = {}
            rejection = {}
            promiseReturnedByFactory = Q.reject rejection
            rejectionRejection = {}
            id = {}

            dependencies =
                getFactory: ->
                    ->
                        promiseReturnedByFactory
                emitPromise: (arg1, arg2, arg3) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    test.equals arg3, promiseReturnedByFactory
                rejectionRejection: (arg1, arg2, arg3) ->
                    test.equals arg1, container
                    test.equals arg2, id
                    test.equals arg3, rejection
                    return rejectionRejection

            callFactory = core.callFactory dependencies

            promise = callFactory container, id, Q.resolve [1, 2]

            promise.fail (value) ->
                test.equals value, rejectionRejection
                test.done()

    'overloadedInject':

        'containers and callback': (test) ->
            test.expect 5

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            dependencies =
                arrayify: (arg1) ->
                    test.equals arg1, container
                    return containers
                parseFunctionArguments: (arg1) ->
                    test.equals arg1, cb
                    return dependencyIds
                inject: (arg1, arg2, arg3) ->
                    test.equals arg1, containers
                    test.equals arg2, dependencyIds
                    test.equals arg3, cb

            overloadedInject = core.overloadedInject dependencies

            overloadedInject container, cb

            test.done()

        'containers, dependencyIds and callback': (test) ->
            test.expect 4

            container = {}
            containers = [{}]
            dependencyIds = {}
            cb = ->

            dependencies =
                arrayify: (arg1) ->
                    test.equals arg1, container
                    return containers
                inject: (arg1, arg2, arg3) ->
                    test.equals arg1, containers
                    test.equals arg2, dependencyIds
                    test.equals arg3, cb

            overloadedInject = core.overloadedInject dependencies

            overloadedInject container, dependencyIds, cb

            test.done()

        '2 or 3 arguments required': (test) ->
            test.expect 2

            overloadedInject = core.overloadedInject {}

            try
                overloadedInject()
            catch err
                test.equals err.message, '2 or 3 arguments required but 0 were given'

            try
                overloadedInject 1, 2, 3, 4
            catch err
                test.equals err.message, '2 or 3 arguments required but 4 were given'

            test.done()

        'at least 1 container required': (test) ->
            test.expect 1

            dependencies =
                arrayify: ->
                    return []

            overloadedInject = core.overloadedInject dependencies

            try
                overloadedInject {}, 2
            catch err
                test.equals err.message, 'at least 1 container is required'
                test.done()

        'cb must be a function': (test) ->
            test.expect 2

            dependencies =
                arrayify: ->
                    return [{}]

            overloadedInject = core.overloadedInject dependencies

            try
                overloadedInject {}, 2
            catch err
                test.equals err.message, 'cb must be a function'

            try
                overloadedInject {}, [], 2
            catch err
                test.equals err.message, 'cb must be a function'

            test.done()
