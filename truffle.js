// Allows us to use ES6 in our migrations and tests.
//require('babel-register')

module.exports = {
  networks: {
    "development": {
      host: "localhost",
      port: 8545,
      network_id: 2,
    },
    "live": {
     network_id: 1,
     host: "192.168.11.8",
     port: 8545,
   }
  }
};
