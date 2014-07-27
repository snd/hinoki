module.exports.configPort = function(env) {
  return env.PORT;
};

module.exports.configDatabaseUrl = function(env) {
  return env.DATABASE_URL;
};
