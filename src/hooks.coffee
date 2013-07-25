module.exports =

    onCircle: (chain) ->
        throw new Error "circular dependency #{chain.join(' <- ')}"

    onException: (id, err) ->
        throw new Error "exception in factory '#{id}': #{err}"

    onRejection: (id, err) ->
        throw new Error "promise returned from factory '#{id}' was rejected with: #{err}"
