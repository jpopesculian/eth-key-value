const webpack = require('webpack')
const path = require('path')

module.exports = {
  entry: {
    main: ['./contracts/HelloWorld.sol']
  },
  module: {
    rules: [
      {
        test: /\.sol/,
        use: [
          {
            loader: 'json-loader'
          },
          {
            loader: 'truffle-solidity-loader',
            options: {
              network: 'development',
              migrations_directory: path.resolve(__dirname, './migrations'),
              contracts_build_directory: path.resolve(
                __dirname,
                './build/contracts'
              )
            }
          }
        ]
      }
    ]
  }
}
