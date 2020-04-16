const keys = require('./keys') // import keys for connection to Redis
const redis = require('redis') // import Redis Client

const redisClient = redis.createClient({ // create Redis Client
  host: keys.redisHost,
  port: keys.redisPort,
  retry_strategy: () => 1000   // this tells to our Redis Server if we ever lose the connection then try to reconnect to server every 1000ms

})

const sub = redisClient.duplicate(); // sub stands for subscription

// function to calculate Fibonacci value
const fib = index => {
    if (index < 2) return 1;
    return fib(index-1) + fib(index - 2);
}

/*
everytime we get a new message (message is index to calculate):
    - calculate fibonacci number
    - insert that in hashed (hset) values called values (so key: index value: fib(index))
*/
sub.on('message', (channel, message) => {
    redisClient.hset('values', message, fib(+message))
})

sub.subscribe('insert') // subscribe for any inser event then calculate value and push it to Redis Server
