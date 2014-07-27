module.exports.startServer = function(
  console,
  database,
  configPort
) {
  return function() {
    console.log('starting server on port', configPort, 'using database', database);
  };
};
