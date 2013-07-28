module.exports = {
    process: function() {
        return process;
    },
    commandLineArguments: function(process) {
        return process.argv.slice(2);
    }
}
