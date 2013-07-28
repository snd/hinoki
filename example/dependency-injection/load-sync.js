var fs = require('fs');
var path = require('path');

var loadSync = function(name, object) {
    var stat = fs.statSync(name);
    if (stat.isFile()) {
        var ext = path.extname(name);
        if (ext !== '.js' && ext !== '.coffee') {
            return;
        }
        var exp = require(name);
        Object.keys(exp).map(function(key) {
            if (object[key]) {
                throw new Error('duplicate service: ' + key);
            }
            object[key] = exp[key];
        });
    } else if (stat.isDirectory()) {
        var filenames = fs.readdirSync(name);
        filenames.forEach(function(filename) {
            loadSync(path.join(name, filename), object);
        });
    }
};

module.exports = loadSync;
