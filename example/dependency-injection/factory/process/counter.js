module.exports = {
    counterState: function() {
        return {
            counter: 0
        };
    },
    incrementCounter: function(counterState) {
        return function() {
            return counterState.counter++
        };
    }
};
