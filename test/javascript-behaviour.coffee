test = require 'tape'
Promise = require 'bluebird'
helfer = require 'helfer'

hinoki = require '../lib/hinoki'

test 'return null or undefined', (t) ->
  f = ->
  t.ok not helfer.isNull f()
  t.ok helfer.isUndefined f()

  g = -> return
  t.ok not helfer.isNull g()
  t.ok helfer.isUndefined g()

  h = -> return undefined
  t.ok not helfer.isNull h()
  t.ok helfer.isUndefined h()

  h = -> return null
  t.ok helfer.isNull h()
  t.ok not helfer.isUndefined h()

  t.end()

test 'properties null or undefined', (t) ->
  a = {}
  t.ok not helfer.isNull a.t
  t.ok helfer.isUndefined a.t
  t.ok not helfer.isNull a['t']
  t.ok helfer.isUndefined a['t']

  b =
    t: undefined
  t.ok not helfer.isNull b.t
  t.ok helfer.isUndefined b.t

  c =
    t: null
  t.ok helfer.isNull c.t
  t.ok not helfer.isUndefined c.t

  d =
    t: null
  delete d.t
  t.ok not helfer.isNull d.t
  t.ok helfer.isUndefined d.t

  t.end()

test 'promise null or undefined', (t) ->
  Promise.resolve().then (v) ->
    t.ok not helfer.isNull v
    t.ok helfer.isUndefined v

    t.end()
