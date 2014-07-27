module.exports.startServer = function(
  console,
  getUserWhereId,
  configPort
) {
  return function() {
    console.log('starting server on port', configPort);
  };
};
