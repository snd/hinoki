test = require 'tape'
Promise = require 'bluebird'

hinoki = require '../lib/hinoki'

module.exports =

test 'bluebird and hinoki work in such a way that the order of dependency resolution is deterministic', (t) ->
  t.plan 28 * 2 + 9

  alphaBravoPromise = Promise.resolve('alpha_bravo')
  deltaPromise = Promise.resolve('delta')

  factories =
    bravo: -> 'bravo'
    delta: -> deltaPromise
    alpha_bravo: (alpha, bravo) ->
      alphaBravoPromise
    alpha_charlie: (alpha, charlie) ->
      alpha + '_' + charlie
    alpha_delta: (alpha, delta) ->
      alpha + '_' + delta
    bravo_charlie: (bravo, charlie) ->
      bravo + '_' + charlie
    bravo_delta: (bravo, delta) ->
      bravo + '_' + delta
    charlie_delta: (charlie, delta) ->
      charlie + '_' + delta

  source = hinoki.source factories

  lifetime1 =
    alpha: 'alpha'

  lifetime2 =
    charlie: 'charlie'

################################################################################
# sync (things that happen synchronously during the call to hinoki)

  expectedSyncEvents = ->
    [

################################################################################
# alpha_bravo

      {
        event: 'sourceReturnedFactory'
        path: ['alpha_bravo']
        factory: factories.alpha_bravo
      }
      {
        event: 'lifetimeHasValue',
        path: ['alpha', 'alpha_bravo']
        value: lifetime1.alpha
        lifetime: lifetime1
        lifetimeIndex: 0
      }
      {
        event: 'sourceReturnedFactory'
        path: ['bravo', 'alpha_bravo']
        factory: factories.bravo
      }

################################################################################
# bravo_charlie

      {
        event: 'sourceReturnedFactory'
        path: ['bravo_charlie']
        factory: factories.bravo_charlie
      }
      # lifetime has promise for the result of the call to the
      # factory of bravo
      {
        event: 'lifetimeHasPromise'
        path: ['bravo', 'bravo_charlie']
        promise: lifetime1.bravo
        lifetime: lifetime1
        lifetimeIndex: 0
      }
      {
        event: 'lifetimeHasValue'
        path: ['charlie', 'bravo_charlie']
        value: 'charlie'
        lifetime: lifetime2
        lifetimeIndex: 1
      }

################################################################################
# alpha_charlie

      {
        event: 'sourceReturnedFactory'
        path: ['alpha_charlie']
        factory: factories.alpha_charlie
      }
      {
        event: 'lifetimeHasValue',
        path: ['alpha', 'alpha_charlie']
        value: lifetime1.alpha
        lifetime: lifetime1
        lifetimeIndex: 0
      }
      {
        event: 'lifetimeHasValue'
        path: ['charlie', 'alpha_charlie']
        value: lifetime2.charlie
        lifetime: lifetime2
        lifetimeIndex: 1
      }

################################################################################
# charlie_delta

      {
        event: 'sourceReturnedFactory'
        path: ['charlie_delta']
        factory: factories.charlie_delta
      }
      {
        event: 'lifetimeHasValue',
        path: ['charlie', 'charlie_delta']
        value: lifetime2.charlie
        lifetime: lifetime2
        lifetimeIndex: 1
      }
      {
        event: 'sourceReturnedFactory'
        path: ['delta', 'charlie_delta']
        factory: factories.delta
      }

################################################################################
# bravo_delta

      {
        event: 'sourceReturnedFactory'
        path: ['bravo_delta']
        factory: factories.bravo_delta
      }
      {
        event: 'lifetimeHasPromise',
        path: ['bravo', 'bravo_delta']
        promise: lifetime1.bravo
        lifetime: lifetime1
        lifetimeIndex: 0
      }
      {
        event: 'lifetimeHasPromise'
        path: ['delta', 'bravo_delta']
        promise: lifetime1.delta
        lifetime: lifetime1
        lifetimeIndex: 0
      }

################################################################################
# alpha_delta

      {
        event: 'sourceReturnedFactory'
        path: ['alpha_delta']
        factory: factories.alpha_delta
      }
      {
        event: 'lifetimeHasValue',
        path: ['alpha', 'alpha_delta']
        value: lifetime1.alpha
        lifetime: lifetime1
        lifetimeIndex: 0
      }
      {
        event: 'lifetimeHasPromise'
        path: ['delta', 'alpha_delta']
        promise: lifetime1.delta
        lifetime: lifetime1
        lifetimeIndex: 0
      }
    ]

################################################################################
# async (things that happen asynchronously on various following ticks)

  expectedAsyncEvents = ->
    [
      # alpha already had a value

      # we asked for bravo next
      {
        event: 'factoryReturnedValue'
        path: ['bravo', 'alpha_bravo']
        factory: factories.bravo
        value: 'bravo'
      }
      # we asked for bravo_charlie next
      # but bravo was just injected into bravo_charlie

      # alpha and charlie both already had values so the factory
      # could be called immeditately and returned a value which
      # we can handle immediately
      {
        event: 'factoryReturnedValue'
        path: ['alpha_charlie']
        factory: factories.alpha_charlie
        value: 'alpha_charlie'
      }

      # we asked for delta next
      {
        event: 'factoryReturnedPromise'
        path: ['delta', 'charlie_delta']
        factory: factories.delta
        promise: deltaPromise
      }

      # we asked for alpha_delta next but delta is not ready yet
      # alpha_delta is not ready yet

      # we asked for bravo charlie next
      {
        event: 'factoryReturnedValue'
        path: ['bravo_charlie']
        factory: factories.bravo_charlie
        value: 'bravo_charlie'
      }

      # delta is ready
      {
        event: 'promiseResolved'
        path: ['delta', 'charlie_delta']
        factory: factories.delta
        value: 'delta'
      }

      {
        event: 'factoryReturnedPromise'
        path: ['alpha_bravo']
        factory: factories.alpha_bravo
        promise: alphaBravoPromise
      }

      {
        event: 'factoryReturnedValue'
        path: ['bravo_delta']
        factory: factories.bravo_delta
        value: 'bravo_delta'
      }
      {
        event: 'factoryReturnedValue'
        path: ['alpha_delta']
        factory: factories.alpha_delta
        value: 'alpha_delta'
      }

      {
        event: 'promiseResolved'
        path: ['alpha_bravo']
        factory: factories.alpha_bravo
        value: 'alpha_bravo'
      }

      {
        event: 'factoryReturnedValue'
        path: ['charlie_delta']
        factory: factories.charlie_delta
        value: 'charlie_delta'
      }
    ]

  callToDebug = 0

  # order in which we ask for things:
  # alpha
  # bravo
  # charlie
  # delta

  hinoki.debug = (actualEvent) ->
    index = callToDebug++
    if index < expectedSyncEvents().length
      t.equal true, isSync
      expectedEvent = expectedSyncEvents()[index]
    else
      t.equal false, isSync
      expectedEvent = expectedAsyncEvents()[index - expectedSyncEvents().length]

    t.deepEqual expectedEvent, actualEvent

  isSync = true

  hinoki source, [lifetime1, lifetime2], (
    alpha_bravo
    bravo_charlie
    alpha_charlie
    charlie_delta
    bravo_delta
    alpha_delta
  ) ->
    t.equal isSync, false

    t.equal alpha_bravo, 'alpha_bravo'
    t.equal alpha_charlie, 'alpha_charlie'
    t.equal alpha_delta, 'alpha_delta'
    t.equal bravo_charlie, 'bravo_charlie'
    t.equal bravo_delta, 'bravo_delta'
    t.equal charlie_delta, 'charlie_delta'

    t.deepEqual lifetime1,
      alpha: 'alpha'
      bravo: 'bravo'
      delta: 'delta'
      alpha_bravo: 'alpha_bravo'
      alpha_delta: 'alpha_delta'
      bravo_delta: 'bravo_delta'
    t.deepEqual lifetime2,
      charlie: 'charlie'
      alpha_charlie: 'alpha_charlie'
      bravo_charlie: 'bravo_charlie'
      charlie_delta: 'charlie_delta'

    delete hinoki.debug

    t.end()

  isSync = false
