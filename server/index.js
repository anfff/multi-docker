const keys = require('./keys');

// ------ Express App Setup
const express = require('express');
const bodyParser = require('body-parser'); // parse incoming request from React Aoo and turned the body of request to json
const cors = require('cors'); // cors - Cross Origin Resource Sharing (allow us to make requests from one domain (React app running on) to a completely different domain / port)

const app = expres(); // create new express app respons / request http
app.use(cors()); // tell app to use corse
app.use(bodyParser.json());

// ------ Postgres Client Setup (communicate with postgres server)
const { Pool } = require('pg');
const pgClient = new Pool({
  user: keys.pgUser,
  host: keys.pgHost,
  database: keys.pgDatabase,
  password: keys.pgPassword,
  port: keys.pgPort,
});
pgClient.on('error', () => console.log('Last PG connection')); // if connection break then console.log

// table holding inserted indexes
pgClient
  .query('CREATE TABLE IF NOT EXISTS values (number INT)') // create table
  .catch((err) => console.log(err)); // if something goes wrong console.log error

// ------  Redis Client Setup (communicate with redis server)
const redis = require('redis');
const redisClient =redis.createClient({
  host: keys.redisHost,
  port: keys.redisPort,
  retry_strategy: () => 1000
});

// duplicate connections is required because each of connection could has only one purpose (listenig, publishing)
const redisPublisher = redisClient.duplicate();

// ------ Express route handlers
app.get('/', (req, res) => {
  res.send('Hi');
})

// return all the indexes that have been ever submited to our application (pg)
app.get('/values/all', async (req, res) => {
  const values = await pgClient.query('SELECT * FROM values') // get all values from pg table

  res.send(values.rows) // send information only abour result (additionaly some other stuff is merged like time of query etc.)
})

// return all the indexes - values that have been ever submited to our application (redis)
app.get('/values/current', async (req,res) => {
  redisClient.hgetall('values', (err, values) => { // get those values
      res.send(values)
  })
})

// send request to server if user input the index
app.post('/values', async (req, res) => {
  const index = req.body.index;

  if (parseInt(index) > 40) {
      return res.status(422).send('Index to high')
  }

  redisClient.hset('values', index, 'Nothing yet!') // insert 'Nothing yet' which will be replaced by value after calculations finished
  redisPublisher.publish('insert', index) // message for worker process with information that is time to pull a new value and start calculating
  pgClient.query('INSERT INTO values(number) VALUES($1)', [index]); // insert index in pg table

  res.send({working: true}); // send info that we're working with calculation
})

app.listen(5000, err => {
  console.log('Listening');
})
