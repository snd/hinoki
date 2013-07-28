module.exports = {
    config: function(commandLineArguments, defaults) {
        if (!commandLineArguments[0]) {
            var port = defaults.port;
        } else {
            var port = parseInt(commandLineArguments[0], 10);
            if (isNaN(port)) {
                throw new Error('port is not a number');
            }
        }
        if (!commandLineArguments[1]) {
            var increment = defaults.increment;
        } else {
            var increment = parseInt(commandLineArguments[1], 10);
            if (isNaN(increment)) {
                throw new Error('increment is not a number');
            }
        }

        return {
            port: port,
            increment: increment
        };
    }
};
