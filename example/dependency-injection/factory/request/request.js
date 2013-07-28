module.exports = {
    url: function(req) {
        return req.url;
    },
    isFavicon: function(url) {
        return url.indexOf('/favicon.ico') === 0;
    }
};
