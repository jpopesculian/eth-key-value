getHeadBlockNumber = web3 =>
  new Promise((resolve, reject) =>
    web3.eth.getBlockNumber((err, num) => {
      if (err) {
        return reject(err)
      }
      resolve(num)
    })
  )

module.exports = async (web3, account, startBlockNumber, endBlockNumber) => {
  if (!endBlockNumber) {
    endBlockNumber = await getHeadBlockNumber(web3)
  }
  if (!startBlockNumber) {
    startBlockNumber = endBlockNumber - 1000
  }
  startBlockNumber = Math.max(0, startBlockNumber)
  endBlockNumber = Math.max(endBlockNumber, startBlockNumber)

  console.log(
    'Searching for transactions to/from account "' +
      account +
      '" within blocks ' +
      startBlockNumber +
      ' and ' +
      endBlockNumber
  )

  return function*() {
    for (let i = startBlockNumber; i <= endBlockNumber; i++) {
      let block = web3.eth.getBlock(i, true)
      if (!block) {
        continue
      }
      for (e of block.transactions) {
        if (account == '*' || account == e.from || account == e.to) {
          yield {
            hash: e.hash,
            nonce: e.nonce,
            blockHash: e.blockHash,
            blockNumber: e.blockNumber,
            transactionIndex: e.transactionIndex,
            from: e.from,
            to: e.to,
            value: e.value,
            time: new Date(block.timestamp * 1000),
            gasPrice: e.gasPrice,
            gas: e.gas,
            input: e.inp
          }
        }
      }
    }
  }
}
