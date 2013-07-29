module.exports = {
    notFound: function(res) {
        return function() {
            res.status = 404;
            res.end('not found');
        };
    },
    sendText: function(res) {
        return function(text) {
            res.end(text);
        };
    }
};
