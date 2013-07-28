module.exports = {
    requestListener: function(makeRequestListener) {
        return makeRequestListener(function(
            url,
            isFavicon,
            notFound,
            incrementCounter,
            sendText
        ) {
            if (isFavicon) {
                notFound();
                return;
            }

            var count = incrementCounter();
            sendText('you made ' + count + ' requests');
        });
    }
};
