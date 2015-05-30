Promise = require 'bluebird'

hinoki = require '../src/hinoki'

module.exports =

  'hinokis way of working and calls to debug are deterministic': (test) ->
    test.expect 19

    alphaBravoPromise = Promise.resolve('alpha_bravo')

    factories =
      bravo: -> 'bravo'
      charlie: -> 'charlie'
      alpha_bravo: (alpha, bravo) ->
        alphaBravoPromise
      bravo_charlie: (bravo, charlie) ->
        bravo + '_' + charlie
      alpha_charlie: (alpha, charlie) ->
        alpha + '_' + charlie

    source = hinoki.source factories

    lifetime =
      alpha: 'alpha'

    expectedEvents = ->
      [
        # get alpha_bravo (get -> alpha_bravo)
        # alpha_bravo has a factory (get -> alpha_bravo)
        {
          event: 'sourceReturnedFactory'
          path: ['alpha_bravo']
          factory: factories.alpha_bravo
        }
        # alpha_bravo factory needs alpha (get -> alpha_bravo -> alpha)
        # alpha has a value (get -> alpha_bravo -> alpha)
        {
          event: 'lifetimeHasValue',
          path: ['alpha', 'alpha_bravo']
          value: lifetime.alpha
          lifetime: lifetime
        }
        # alpha_bravo needs bravo (get -> alpha_bravo -> bravo)
        # bravo has a factory (get -> alpha_bravo -> bravo)
        {
          event: 'sourceReturnedFactory'
          path: ['bravo', 'alpha_bravo']
          factory: factories.bravo
        }
        # end of sync part of alpha_bravo

        # get bravo_charlie (get -> bravo_charlie)
        # bravo_charlie has a factory (get -> bravo_charlie)
        {
          event: 'sourceReturnedFactory'
          path: ['bravo_charlie']
          factory: factories.bravo_charlie
        }
        # bravo_charlie needs bravo (get -> bravo_charlie -> bravo)
        # bravos factory was already called (get -> bravo_charlie -> bravo)
        {
          event: 'lifetimeHasPromise'
          path: ['bravo', 'bravo_charlie']
          promise: lifetime.bravo
          lifetime: lifetime
        }
        # bravo_charlie needs charlie (get -> bravo_charlie -> charlie)
        # charlie has a factory (get -> bravo_charlie -> charlie)
        {
          event: 'sourceReturnedFactory'
          path: ['charlie', 'bravo_charlie']
          factory: factories.charlie
        }
        # end of sync part of bravo_charlie

        # get alpha_charlie (get -> alpha_charlie)
        # alpha_charlie has a factory (get -> alpha_charlie)
        {
          event: 'sourceReturnedFactory'
          path: ['alpha_charlie']
          factory: factories.alpha_charlie
        }
        # alpha_charlie factory needs alpha (get -> alpha_charlie -> alpha)
        # alpha has a value (get -> alpha_charlie -> alpha)
        {
          event: 'lifetimeHasValue',
          path: ['alpha', 'alpha_charlie']
          value: lifetime.alpha
          lifetime: lifetime
        }
        # alpha_charlie needs charlie (get -> alpha_charlie -> charlie)
        # charlies factory was already called (get -> alpha_charlie -> bravo)
        {
          event: 'lifetimeHasPromise'
          path: ['charlie', 'alpha_charlie']
          promise: lifetime.charlie
          lifetime: lifetime
        }
        # end of sync part of alpha_charlie

        # async... on a following tick

        {
          event: 'factoryReturnedValue'
          path: ['bravo', 'alpha_bravo']
          factory: factories.bravo
          value: 'bravo'
        }
        {
          event: 'factoryReturnedValue'
          path: ['charlie', 'bravo_charlie']
          factory: factories.charlie
          value: 'charlie'
        }
        {
          event: 'factoryReturnedValue'
          path: ['alpha_charlie']
          factory: factories.alpha_charlie
          value: 'alpha_charlie'
        }
        {
          event: 'factoryReturnedPromise'
          path: ['alpha_bravo']
          factory: factories.alpha_bravo
          promise: alphaBravoPromise
        }
        {
          event: 'factoryReturnedValue'
          path: ['bravo_charlie']
          factory: factories.bravo_charlie
          value: 'bravo_charlie'
        }

        # async... on a following tick

        {
          event: 'promiseResolved'
          path: ['alpha_bravo']
          factory: factories.alpha_bravo
          value: 'alpha_bravo'
        }
      ]

    callToDebug = 0

    hinoki.debug = (actualEvent) ->
      expectedEvent = expectedEvents()[callToDebug++]
      test.deepEqual expectedEvent, actualEvent

    hinoki source, lifetime, (alpha_bravo, bravo_charlie, alpha_charlie) ->
      test.equal alpha_bravo, 'alpha_bravo'
      test.equal bravo_charlie, 'bravo_charlie'
      test.equal alpha_charlie, 'alpha_charlie'
      test.deepEqual lifetime,
        alpha: 'alpha'
        bravo: 'bravo'
        charlie: 'charlie'
        alpha_charlie: 'alpha_charlie'
        bravo_charlie: 'bravo_charlie'
        alpha_bravo: 'alpha_bravo'
      test.done()
