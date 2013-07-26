module.exports =

    # called when a circular dependency is encountered
    circle: (chain) ->
        throw new Error "circular dependency #{chain.join(' <- ')}"

    # called when a factory function throws an exception
    exception: (chain, err) ->
        throw new Error "exception in factory '#{chain[0]}': #{err}"

    # called when a promise that was returned from a factory is rejected
    rejection: (chain, err) ->
        throw new Error "promise returned from factory '#{chain[0]}' was rejected with: #{err}"

    # called when no factory was found for a service
    notFound: (chain) ->
        throw new Error "missing factory '#{chain[0]}' (#{chain.join(' <- ')})"

    # called when a factory is not a function
    notFunction: (chain, factory) ->
        throw new Error "factory '#{chain[0]}' is not a function: #{factory}"

    # # additional hooks which are useful for debugging:

    # # called when an instance is found
    # instanceFound: (chain, instance) ->

    # # called when a factory is found
    # factoryFound: (chain, factory, factoryDependencyIds) ->

    # # called when a factory returns an instance
    # instance: (chain, instance) ->

    # # called when a factory returns a promise
    # promise: (chain, promise) ->

    # # called when a promise is resolved into an instance
    # resolution: (chain, instance) ->

    # called right before a factory is called
    # factory: (chain, factory, arguments) ->
