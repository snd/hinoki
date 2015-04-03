Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'hinokis way of working and calls to debug are deterministic': (test) ->
    test.expect 58

    alphaBravoPromise = Promise.resolve('alpha_bravo')

    container =
      values:
        alpha: 'alpha'
      factories:
        bravo: -> 'bravo'
        charlie: -> 'charlie'
        alpha_bravo: (alpha, bravo) ->
          alphaBravoPromise
        bravo_charlie: (bravo, charlie) ->
          bravo + '_' + charlie
        alpha_charlie: (alpha, charlie) ->
          alpha + '_' + charlie

    noopResolver = (name, container2, inner, debug2) ->
      test.equal container, container2
      test.equal debug, debug2
      inner name

    expectedEvents = ->
      [
        # get alpha_bravo (get -> alpha_bravo)
        {
          event: 'defaultResolverWasCalled'
          path: ['alpha_bravo']
          container: container
          resolution:
            factory: container.factories.alpha_bravo
            name: 'alpha_bravo'
        }
        {
          event: 'customResolverWasCalled'
          path: ['alpha_bravo']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.alpha_bravo
            name: 'alpha_bravo'
        }
        # alpha_bravo has a factory (get -> alpha_bravo)
        {
          event: 'factoryWasResolved'
          path: ['alpha_bravo']
          resolution:
            factory: container.factories.alpha_bravo
            name: 'alpha_bravo'
            container: container
        }
        # alpha_bravo factory needs alpha (get -> alpha_bravo -> alpha)
        {
          event: 'defaultResolverWasCalled',
          path: ['alpha', 'alpha_bravo']
          container: container
          resolution:
            value: container.values.alpha
            name: 'alpha'
        }
        {
          event: 'customResolverWasCalled',
          path: ['alpha', 'alpha_bravo']
          container: container
          resolver: noopResolver
          resolution:
            value: container.values.alpha
            name: 'alpha'
        }
        # alpha has a value (get -> alpha_bravo -> alpha)
        {
          event: 'valueWasResolved',
          path: ['alpha', 'alpha_bravo']
          resolution:
            value: container.values.alpha
            name: 'alpha'
            container: container
        }
        # alpha_bravo needs bravo (get -> alpha_bravo -> bravo)
        {
          event: 'defaultResolverWasCalled',
          path: ['bravo', 'alpha_bravo']
          container: container
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
        }
        {
          event: 'customResolverWasCalled',
          path: ['bravo', 'alpha_bravo']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
        }
        # bravo has a factory (get -> alpha_bravo -> bravo)
        {
          event: 'factoryWasResolved'
          path: ['bravo', 'alpha_bravo']
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
            container: container
        }
        # end of sync part of alpha_bravo

        # get bravo_charlie (get -> bravo_charlie)
        {
          event: 'defaultResolverWasCalled'
          path: ['bravo_charlie']
          container: container
          resolution:
            factory: container.factories.bravo_charlie
            name: 'bravo_charlie'
        }
        {
          event: 'customResolverWasCalled'
          path: ['bravo_charlie']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.bravo_charlie
            name: 'bravo_charlie'
        }
        # bravo_charlie has a factory (get -> bravo_charlie)
        {
          event: 'factoryWasResolved'
          path: ['bravo_charlie']
          resolution:
            factory: container.factories.bravo_charlie
            name: 'bravo_charlie'
            container: container
        }
        # bravo_charlie needs bravo (get -> bravo_charlie -> bravo)
        {
          event: 'defaultResolverWasCalled',
          path: ['bravo', 'bravo_charlie']
          container: container
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
        }
        {
          event: 'customResolverWasCalled',
          path: ['bravo', 'bravo_charlie']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
        }
        # bravo has a factory (get -> bravo_charlie -> bravo)
        {
          event: 'factoryWasResolved'
          path: ['bravo', 'bravo_charlie']
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
            container: container
        }
        # bravos factory was already called (get -> bravo_charlie -> bravo)
        {
          event: 'valueIsAlreadyAwaitingResolution'
          path: ['bravo', 'bravo_charlie']
          resolution:
            factory: container.factories.bravo
            name: 'bravo'
            container: container
          promise: container.promisesAwaitingResolution?.bravo
        }
        # bravo_charlie needs charlie (get -> bravo_charlie -> charlie)
        {
          event: 'defaultResolverWasCalled'
          path: ['charlie', 'bravo_charlie']
          container: container
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
        }
        {
          event: 'customResolverWasCalled'
          path: ['charlie', 'bravo_charlie']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
        }
        # charlie has a factory (get -> bravo_charlie -> charlie)
        {
          event: 'factoryWasResolved'
          path: ['charlie', 'bravo_charlie']
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
            container: container
        }
        # end of sync part of bravo_charlie

        # get alpha_charlie (get -> alpha_charlie)
        {
          event: 'defaultResolverWasCalled'
          path: ['alpha_charlie']
          container: container
          resolution:
            factory: container.factories.alpha_charlie
            name: 'alpha_charlie'
        }
        {
          event: 'customResolverWasCalled'
          path: ['alpha_charlie']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.alpha_charlie
            name: 'alpha_charlie'
        }
        # alpha_charlie has a factory (get -> alpha_charlie)
        {
          event: 'factoryWasResolved'
          path: ['alpha_charlie']
          resolution:
            factory: container.factories.alpha_charlie
            name: 'alpha_charlie'
            container: container
        }
        # alpha_charlie factory needs alpha (get -> alpha_charlie -> alpha)
        {
          event: 'defaultResolverWasCalled',
          path: ['alpha', 'alpha_charlie']
          container: container
          resolution:
            value: container.values.alpha
            name: 'alpha'
        }
        {
          event: 'customResolverWasCalled',
          path: ['alpha', 'alpha_charlie']
          container: container
          resolver: noopResolver
          resolution:
            value: container.values.alpha
            name: 'alpha'
        }
        # alpha has a value (get -> alpha_charlie -> alpha)
        {
          event: 'valueWasResolved',
          path: ['alpha', 'alpha_charlie']
          resolution:
            value: container.values.alpha
            name: 'alpha'
            container: container
        }
        # alpha_charlie needs charlie (get -> alpha_charlie -> charlie)
        {
          event: 'defaultResolverWasCalled'
          path: ['charlie', 'alpha_charlie']
          container: container
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
        }
        {
          event: 'customResolverWasCalled'
          path: ['charlie', 'alpha_charlie']
          container: container
          resolver: noopResolver
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
        }
        # charlie has a factory (get -> alpha_charlie -> charlie)
        {
          event: 'factoryWasResolved'
          path: ['charlie', 'alpha_charlie']
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
            container: container
        }
        # charlies factory was already called (get -> alpha_charlie -> bravo)
        {
          event: 'valueIsAlreadyAwaitingResolution'
          path: ['charlie', 'alpha_charlie']
          resolution:
            factory: container.factories.charlie
            name: 'charlie'
            container: container
          promise: container.promisesAwaitingResolution?.charlie
        }
        # end of sync part of alpha_charlie

        # async... on a following tick

        {
          event: 'valueWasCreated'
          path: ['bravo', 'alpha_bravo']
          factory: container.factories.bravo
          value: 'bravo'
          container: container
        }
        {
          event: 'valueWasCreated'
          path: ['charlie', 'bravo_charlie']
          factory: container.factories.charlie
          value: 'charlie'
          container: container
        }
        {
          event: 'valueWasCreated'
          path: ['alpha_charlie']
          factory: container.factories.alpha_charlie
          value: 'alpha_charlie'
          container: container
        }
        {
          event: 'promiseWasCreated'
          path: ['alpha_bravo']
          factory: container.factories.alpha_bravo
          promise: alphaBravoPromise
          container: container
        }
        {
          event: 'valueWasCreated'
          path: ['bravo_charlie']
          factory: container.factories.bravo_charlie
          value: 'bravo_charlie'
          container: container
        }

        # async... on a following tick

        {
          event: 'promiseWasResolved'
          path: ['alpha_bravo']
          factory: container.factories.alpha_bravo
          value: 'alpha_bravo'
          container: container
        }
      ]

    callToDebug = 0

    debug = (actualEvent) ->
      expectedEvent = expectedEvents()[callToDebug++]
      test.deepEqual expectedEvent, actualEvent

    container.resolvers = noopResolver

    hinoki(container, ['alpha_bravo', 'bravo_charlie', 'alpha_charlie'], debug)
      .spread (alpha_bravo, bravo_charlie, alpha_charlie) ->
        test.equal alpha_bravo, 'alpha_bravo'
        test.equal bravo_charlie, 'bravo_charlie'
        test.equal alpha_charlie, 'alpha_charlie'
        test.deepEqual container.values,
          alpha: 'alpha'
          bravo: 'bravo'
          charlie: 'charlie'
          alpha_charlie: 'alpha_charlie'
          bravo_charlie: 'bravo_charlie'
          alpha_bravo: 'alpha_bravo'
        test.ok not container.promisesAwaitingResolution?
        test.done()
