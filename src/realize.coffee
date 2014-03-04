# minimal dependency injection that is required to assemble hinoki itself
#
# qualities:
# - factories must return functions
# - cyclic dependencies are possible
# - no events for debugging and introspection
# - no error handling
# - no promise handling
# - single container only
# - eager dependency resolution (instead of lazy)

parseFunctionArguments = require('./util').parseFunctionArguments

module.exports = (container) ->
  Object.keys(container.factories).forEach (id) ->
    if container.instances[id]?
      throw new Error "factory for #{id} but there is already instance for #{id}"

    factory = container.factories[id]

    dependencyIds = parseFunctionArguments factory

    dependencies = dependencyIds.map (dependencyId) ->
      if container.instances[dependencyId]?
        container.instances[dependencyId]
      else
        # delegate
        ->
          instance = container.instances[dependencyId]
          if not instance?
            throw new Error "missing instance for #{dependencyId}"
          instance.apply null, arguments

    instance = factory.apply null, dependencies

    if not 'function' is typeof instance
      throw new Error "factory for #{id} didn't return a function but #{instance}"

    container.instances[id] = instance
