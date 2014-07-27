module.exports.database = function(
  console,
  configDatabaseUrl
) {
  console.log('connecting to database on', configDatabaseUrl);
  return {
    database: 'DATABASE'
  };
};
