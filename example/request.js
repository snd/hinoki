var hinoki = require('hinoki');
var Promise = require('bluebird');

////////////////////////////////////////////////////////////////////////////////
// process lifetime

processLifetime = {};

processLifetime.values = {
  env: {
    IS_ADMIN_REQUIRED: 'true'
  }
};

processLifetime.factories = {
  configIsAdminRequired: function(env) {
    return env.IS_ADMIN_REQUIRED === 'true'
  },
  isUserAdminWhereId: function() {
    return function(userId) {
    // would usually depend on the database connection and access the database...
      return Promise.delay(userId === 8000, 100);
    };
  }
};

////////////////////////////////////////////////////////////////////////////////
// request lifetime

// assume this to be created for every request
requestLifetime = {};

requestLifetime.values = {
  // assume this is a nodejs request object
  req: {
    url: '/protected',
    session: {
      userId: 9000
    }
  },
  // assume this is a nodejs response object
  res: {
    write: function(string) {
      console.log('req.write:', string);
    },
    end: function() {
      console.log('req.end');
    }
  }
};

requestLifetime.factories = {
  url: function(req) {
    return req.url;
  },
  session: function(req) {
    return req.session;
  },
  currentUserId: function(session) {
    return session.userId;
  },
  isCurrentUserAdmin: function(isUserAdminWhereId, currentUserId) {
    return isUserAdminWhereId(currentUserId);
  },
  sendForbidden: function(res) {
    return function() {
      res.statusCode = 403;
      res.write('Forbidden');
      res.end();
    }
  }
};

////////////////////////////////////////////////////////////////////////////////
// injection

var lifetimes = [
  requestLifetime,
  processLifetime
];

var factory = function(
  url,
  isCurrentUserAdmin,
  sendForbidden,
  configIsAdminRequired
) {
  if (url === '/protected' && !isCurrentUserAdmin && configIsAdminRequired) {
    sendForbidden();
  }

  console.log('processLifetime.values', processLifetime.values);
  console.log('requestLifetime.values', requestLifetime.values);
};

hinoki(lifetimes, hinoki.parseFunctionArguments(factory)).spread(factory);
