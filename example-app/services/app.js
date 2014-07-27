module.exports.startApp = function(
  console,
  startServer,
  startWorkers
) {
  return function() {
    console.log('starting app');
    startWorkers();
    startServer();
  };
};
