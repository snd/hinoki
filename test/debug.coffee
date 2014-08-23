Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'hinokis way of working and calls to debug are deterministic': (test) ->
    test.expect 24
    calls = []
    debug = (arg) -> calls.push arg

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
        expectedCalls = [
          # get alpha_bravo (get -> alpha_bravo)
          {
            event: 'defaultResolverWasCalled'
            path: ['alpha_bravo']
            container: container
            resolution:
              factory: container.factories.alpha_bravo
              name: 'alpha_bravo'
              container: container
          }
          {
            event: 'customResolverWasCalled'
            path: ['alpha_bravo']
            container: container
            resolver: noopResolver
            resolution:
              factory: container.factories.alpha_bravo
              name: 'alpha_bravo'
              container: container
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
              container: container
          }
          {
            event: 'customResolverWasCalled',
            path: ['alpha', 'alpha_bravo']
            container: container
            resolver: noopResolver
            resolution:
              value: container.values.alpha
              name: 'alpha'
              container: container
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
              container: container
          }
          {
            event: 'customResolverWasCalled',
            path: ['bravo', 'alpha_bravo']
            container: container
            resolver: noopResolver
            resolution:
              factory: container.factories.bravo
              name: 'bravo'
              container: container
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
              container: container
          }
          {
            event: 'customResolverWasCalled'
            path: ['bravo_charlie']
            container: container
            resolver: noopResolver
            resolution:
              factory: container.factories.bravo_charlie
              name: 'bravo_charlie'
              container: container
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
        ]
        test.deepEqual calls.slice(0, expectedCalls.length), expectedCalls

        console.log calls[expectedCalls.length]
        console.log (calls.length - expectedCalls.length) + ' to go'
        test.done()
