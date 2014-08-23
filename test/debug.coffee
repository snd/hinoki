Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'hinokis way of working and calls to debug are deterministic': (test) ->
    # test.expect 24

    container =
      values:
        alpha: 'alpha'
      factories:
        bravo: -> 'bravo'
        charlie: -> 'charlie'
        alpha_bravo: (alpha, bravo) ->
          Promise.resolve(alpha + '_' + bravo, 10)
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
      ]

    callToDebug = 0

    missedEvents = []

    debug = (actualEvent) ->
      # if callToDebug is 0
      expectedEvent = expectedEvents()[callToDebug++]
      # console.log "EXPECTED"
      # console.log expectedEvent
      # console.log "ACTUAL"
      # console.log actualEvent
      if expectedEvent?
        test.deepEqual expectedEvent, actualEvent
      else
        missedEvents.push actualEvent

    container.resolvers = noopResolver

    hinoki.get(container, ['alpha_bravo', 'bravo_charlie', 'alpha_charlie'], debug)
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

        console.log missedEvents[0]
        console.log missedEvents.length + ' to go'
        test.done()
