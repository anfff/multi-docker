module.exports = {
  redisHost: process.env.REDIS_HOST,
  redisPort: process.env.REDIS_PORT,
  pgUser: process.env.PGUSER, // pg user that we're logging as
  pgHOST: process.env.PGHOST,
  pgDatabase: process.env.PGDATABASE, // pg database where we will store our data
  pgPassword: process.env.PGPASSWORD, // pg password to db
  pgPort: process.env.PGPORT
};
