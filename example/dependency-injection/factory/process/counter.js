module.exports = {
    counterState: function() {
        return {
            counter: 0
        };
    },
    incrementCounter: function(counterState, config) {
        return function() {
            return counterState.counter += config.increment;
        };
    }
};
