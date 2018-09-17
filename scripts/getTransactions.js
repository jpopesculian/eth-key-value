const getTransactionByAccount = require('./lib/getTransactionByAccount')

const getTransactions = async () => {
  const transactions = await getTransactionByAccount(web3, '*')
  for (transaction of transactions()) {
    console.log(transaction)
  }
}

module.exports = callback => {
  getTransactions().then(callback).catch(callback)
}
