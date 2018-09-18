const KeyValueStore = artifacts.require('./KeyValueStore.sol')

module.exports = deployer => {
  deployer.deploy(KeyValueStore)
}
