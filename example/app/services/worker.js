module.exports.startWorker = function(
  console,
  database
) {
  return function(id) {
    console.log('starting worker', id);
  }
};

module.exports.startWorkers = function(
  console,
  startWorker
) {
  console.log('starting workers');
  return function() {
    startWorker(1);
    startWorker(2);
    startWorker(3);
  };
};
