var hinoki = require('hinoki');
var Promise = require('bluebird');

////////////////////////////////////////////////////////////////////////////////
// process lifetime

var processLifetimeInstances = {
  env: {
    IS_ADMIN_REQUIRED: 'true'
  }
};

var processLifetimeFactories = {
  configIsAdminRequired: function(env) {
    return env.IS_ADMIN_REQUIRED === 'true'
  },
  isUserAdminWhereId: function() {
    return function(userId) {
    // would usually depend on the database connection and access the database...
      return Promise.delay(userId === 9000, 100);
    };
  }
};

var processLifetimeContainer = hinoki.newContainer(
  processLifetimeFactories,
  processLifetimeInstances
);

////////////////////////////////////////////////////////////////////////////////
// request lifetime

var requestLifetimeInstances = {
  // let's assume this is a nodejs request object
  req: {
    url: '/protected',
    session: {
      userId: 9000
    }
  },
  // let's assume this is a nodejs response object
  res: {
    write: function(string) {
      console.log('req.write:', string);
    },
    end: function() {
      console.log('req.end');
    }
  }
};


var requestLifetimeFactories = {
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

// created for every request
var requestLifetimeContainer = hinoki.newContainer(
  requestLifetimeFactories,
  requestLifetimeInstances
);

////////////////////////////////////////////////////////////////////////////////
// injection

var containers = [
  requestLifetimeContainer,
  processLifetimeContainer
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

  console.log('processLifetimeInstances', processLifetimeInstances);
  console.log('requestLifetimeInstances', requestLifetimeInstances);
};

hinoki.get(containers, hinoki.parseFunctionArguments(factory)).spread(factory);
