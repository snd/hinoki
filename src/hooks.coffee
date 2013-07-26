module.exports =

    # called when a circular dependency is encountered
    circle: (chain) ->
        throw new Error "circular dependency #{chain.join(' <- ')}"

    # called when a factory function throws an exception
    exception: (id, err) ->
        throw new Error "exception in factory '#{id}': #{err}"

    # called when a promise that was returned from a factory is rejected
    rejection: (id, err) ->
        throw new Error "promise returned from factory '#{id}' was rejected with: #{err}"

    # called when no factory was found for a service
    notFound: (chain) ->
        throw new Error "missing factory: #{chain.join(' <- ')}"

    # called when a factory is not a function
    notFunction: (id, factory) ->
        throw new Error "factory 'a' is not a function: #{factory}"

    # additional hooks which are useful for debugging:

    # called right before resolved dependencies are injected into a function:
    # onInject: (
    #
    # called when no instance
    # onNoInstance:
    #
    # called right before an instance is added to instances
    # onNewInstance: (id, instance) ->
    #
    # onResolve
