# Promise = require 'bluebird'
#
# hinoki = require '../src/hinoki'
#
# module.exports =
#
#   'hinokis way of working and calls to debug are deterministic': (test) ->
#     test.expect 20
#
#     alphaBravoPromise = Promise.resolve('alpha_bravo')
#
#     lifetime =
#       values:
#         alpha: 'alpha'
#       factories:
#         bravo: -> 'bravo'
#         charlie: -> 'charlie'
#         alpha_bravo: (alpha, bravo) ->
#           alphaBravoPromise
#         bravo_charlie: (bravo, charlie) ->
#           bravo + '_' + charlie
#         alpha_charlie: (alpha, charlie) ->
#           alpha + '_' + charlie
#
#     expectedEvents = ->
#       [
#         # get alpha_bravo (get -> alpha_bravo)
#         # alpha_bravo has a factory (get -> alpha_bravo)
#         {
#           event: 'factoryWasResolved'
#           path: ['alpha_bravo']
#           factorySource: lifetime.factories
#           factory: lifetime.factories.alpha_bravo
#         }
#         # alpha_bravo factory needs alpha (get -> alpha_bravo -> alpha)
#         # alpha has a value (get -> alpha_bravo -> alpha)
#         {
#           event: 'valueWasResolved',
#           path: ['alpha', 'alpha_bravo']
#           value: lifetime.values.alpha
#         }
#         # alpha_bravo needs bravo (get -> alpha_bravo -> bravo)
#         # bravo has a factory (get -> alpha_bravo -> bravo)
#         {
#           event: 'factoryWasResolved'
#           path: ['bravo', 'alpha_bravo']
#           factorySource: lifetime.factories
#           factory: lifetime.factories.bravo
#         }
#         # end of sync part of alpha_bravo
#
#         # get bravo_charlie (get -> bravo_charlie)
#         # bravo_charlie has a factory (get -> bravo_charlie)
#         {
#           event: 'factoryWasResolved'
#           path: ['bravo_charlie']
#           factorySource: lifetime.factories
#           factory: lifetime.factories.bravo_charlie
#         }
#         # bravo_charlie needs bravo (get -> bravo_charlie -> bravo)
#         # bravos factory was already called (get -> bravo_charlie -> bravo)
#         {
#           event: 'valueIsAlreadyAwaitingResolution'
#           path: ['bravo', 'bravo_charlie']
#           promise: lifetime.promisesAwaitingResolution?.bravo
#         }
#         # bravo_charlie needs charlie (get -> bravo_charlie -> charlie)
#         # charlie has a factory (get -> bravo_charlie -> charlie)
#         {
#           event: 'factoryWasResolved'
#           path: ['charlie', 'bravo_charlie']
#           factorySource: lifetime.factories
#           factory: lifetime.factories.charlie
#         }
#         # end of sync part of bravo_charlie
#
#         # get alpha_charlie (get -> alpha_charlie)
#         # alpha_charlie has a factory (get -> alpha_charlie)
#         {
#           event: 'factoryWasResolved'
#           path: ['alpha_charlie']
#           factorySource: lifetime.factories
#           factory: lifetime.factories.alpha_charlie
#         }
#         # alpha_charlie factory needs alpha (get -> alpha_charlie -> alpha)
#         # alpha has a value (get -> alpha_charlie -> alpha)
#         {
#           event: 'valueWasResolved',
#           path: ['alpha', 'alpha_charlie']
#           value: lifetime.values.alpha
#         }
#         # alpha_charlie needs charlie (get -> alpha_charlie -> charlie)
#         # charlies factory was already called (get -> alpha_charlie -> bravo)
#         {
#           event: 'valueIsAlreadyAwaitingResolution'
#           path: ['charlie', 'alpha_charlie']
#           promise: lifetime.promisesAwaitingResolution?.charlie
#         }
#         # end of sync part of alpha_charlie
#
#         # async... on a following tick
#
#         {
#           event: 'valueWasCreated'
#           path: ['bravo', 'alpha_bravo']
#           factory: lifetime.factories.bravo
#           value: 'bravo'
#         }
#         {
#           event: 'valueWasCreated'
#           path: ['charlie', 'bravo_charlie']
#           factory: lifetime.factories.charlie
#           value: 'charlie'
#         }
#         {
#           event: 'valueWasCreated'
#           path: ['alpha_charlie']
#           factory: lifetime.factories.alpha_charlie
#           value: 'alpha_charlie'
#         }
#         {
#           event: 'promiseWasCreated'
#           path: ['alpha_bravo']
#           factory: lifetime.factories.alpha_bravo
#           promise: alphaBravoPromise
#         }
#         {
#           event: 'valueWasCreated'
#           path: ['bravo_charlie']
#           factory: lifetime.factories.bravo_charlie
#           value: 'bravo_charlie'
#         }
#
#         # async... on a following tick
#
#         {
#           event: 'promiseWasResolved'
#           path: ['alpha_bravo']
#           factory: lifetime.factories.alpha_bravo
#           value: 'alpha_bravo'
#         }
#       ]
#
#     callToDebug = 0
#
#     lifetime.debug = (actualEvent) ->
#       expectedEvent = expectedEvents()[callToDebug++]
#       test.deepEqual expectedEvent, actualEvent
#
#     hinoki(lifetime, ['alpha_bravo', 'bravo_charlie', 'alpha_charlie'])
#       .spread (alpha_bravo, bravo_charlie, alpha_charlie) ->
#         test.equal alpha_bravo, 'alpha_bravo'
#         test.equal bravo_charlie, 'bravo_charlie'
#         test.equal alpha_charlie, 'alpha_charlie'
#         test.deepEqual lifetime.values,
#           alpha: 'alpha'
#           bravo: 'bravo'
#           charlie: 'charlie'
#           alpha_charlie: 'alpha_charlie'
#           bravo_charlie: 'bravo_charlie'
#           alpha_bravo: 'alpha_bravo'
#         test.ok not lifetime.promisesAwaitingResolution?
#         test.done()
