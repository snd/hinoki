var fs = require('fs');
var path = require('path');

var hinoki = require('hinoki');

////////////////////////////////////////////////////////////////////////////////
// util

// load and merge all exports from all files in a folder recursively
var loadFolderSync = function(name, object) {
  var stat = fs.statSync(name);
  if (stat.isFile()) {
      var ext = path.extname(name);
      if ((ext !== '.js') && (ext !== '.coffee')) {
        return;
      }
      var exp = require(name);
      Object.keys(exp).map(function(key) {
        if (object[key]) {
          throw new Error('duplicate id: ' + key);
        }
        object[key] = exp[key];
      });
  } else if (stat.isDirectory()) {
    // recurse into directory
    var filenames = fs.readdirSync(name);
    filenames.forEach(function(filename) {
      loadFolderSync(path.join(name, filename), object);
    });
  }
};

////////////////////////////////////////////////////////////////////////////////
// lets go!

var container = {}

container.factories = {};

// add all the exports of all the files in the ./services directory
// to the factories object
loadFolderSync(path.resolve(__dirname, './services'), container.factories)

container.values = {
  // lets mock out the console
  console: {
    log: function() {
      console.log.apply(
        this,
        ['MOCK CONSOLE.LOG:'].concat(Array.prototype.slice.call(arguments))
      );
    }
  },
  // lets mock out process.env
  env: {
    PORT: 9000,
    DATABASE_URL: 'postgres://localhost:5432/database'
  }
};

hinoki(container, 'startApp').then(function(startApp) {
  startApp();
});
