var path = require('path');

var hinoki = require('hinoki');
var loadSync = require('./load-sync');

var processFactories = {};
loadSync(path.join(__dirname, './factory/process'), processFactories);

var requestFactories = {};
loadSync(path.join(__dirname, './factory/request'), requestFactories);

module.exports = function(fun) {
    var processContainer = {
        factories: processFactories,
        instances: {
            makeRequestListener: function(fun) {
                return function(req, res) {
                    var requestContainer = {
                        factories: requestFactories,
                        instances: {
                            req: req,
                            res: res
                        }
                    };
                    hinoki.inject([requestContainer, processContainer], fun);
                };
            }
        }
    };

    hinoki.inject(processContainer, fun);
};
