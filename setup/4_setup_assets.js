const ChronoBankPlatform = artifacts.require('./ChronoBankPlatform.sol')
const ChronoBankPlatformEmitter = artifacts.require('./ChronoBankPlatformEmitter.sol')
const EventsHistory = artifacts.require('./EventsHistory.sol')
const ChronoBankAssetProxy = artifacts.require('./ChronoBankAssetProxy.sol')
const ChronoBankAssetWithFeeProxy = artifacts.require('./ChronoBankAssetWithFeeProxy.sol')
const ChronoBankAsset = artifacts.require('./ChronoBankAsset.sol')
const ChronoBankAssetWithFee = artifacts.require('./ChronoBankAssetWithFee.sol')
const ChronoMint = artifacts.require('./ChronoMint.sol')
const ContractsManager = artifacts.require('./ContractsManager.sol')
const Exchange = artifacts.require('./Exchange.sol')
const Shareable = artifacts.require("./PendingManager.sol");
const TimeHolder = artifacts.require('./TimeHolder.sol')
const Rewards = artifacts.require('./Rewards.sol')
const UserStorage = artifacts.require('./UserStorage.sol');
const UserManager = artifacts.require("./UserManager.sol");
const Vote = artifacts.require('./Vote.sol')
const bytes32fromBase58 = require('../test/helpers/bytes32fromBase58')

function bytes32(stringOrNumber) {
  var zeros = '000000000000000000000000000000000000000000000000000000000000000';
  if (typeof stringOrNumber === "string") {
    return (web3.toHex(stringOrNumber) + zeros).substr(0, 66);
  }
  var hexNumber = stringOrNumber.toString(16);
  return '0x' + (zeros + hexNumber).substring(hexNumber.length - 1);
}

const SYMBOL = 'TIME'
const SYMBOL2 = 'LHT'
const NAME = 'Time Token'
const DESCRIPTION = 'ChronoBank Time Shares'
const NAME2 = 'Labour-hour Token'
const DESCRIPTION2 = 'ChronoBank Lht Assets'
const BASE_UNIT = 8
const IS_REISSUABLE = true
const IS_NOT_REISSUABLE = false
const fakeArgs = [0, 0, 0, 0, 0, 0, 0, 0]
const BALANCE_ETH = 1000

let chronoBankPlatform
let chronoMint
let contractsManager
let timeHolder
let eventsHistory
let chronoBankPlatformEmitter
let rewards
let exchange
let chronoBankAssetWithFee
let chronoBankAssetWithFeeProxy

let accounts
let params
let paramsGas

var getAcc = function() {
    return new Promise(function(resolve, reject) {
    web3.eth.getAccounts((err, acc) => {
    console.log(acc);
    resolve(acc);
})
})
}

var exit = function() {
    process.exit()
}

module.exports = (callback) => {
    return getAcc()
    .then(r => {
      accounts = r
      params = {from: accounts[0]}
      paramsGas = {from: accounts[0], gas: 3000000}
      return UserStorage.deployed()
    }).then(function (instance) {
       return instance.addOwner(UserManager.address)
    }).then(function () {
       return ChronoMint.deployed()
    }).then(function (instance) {
       return instance.init(UserStorage.address, Shareable.address, ContractsManager.address)
    }).then(function () {
       return ContractsManager.deployed()
    }).then(function (instance) {
       return instance.init(UserStorage.address, Shareable.address)
    }).then(function () {
       return Shareable.deployed()
    }).then(function (instance) {
       return instance.init(UserStorage.address)
    }).then(function () {
       return UserManager.deployed()
    }).then(function (instance) {
       return instance.init(UserStorage.address, Shareable.address)
    }).then(function () {
      return ChronoBankPlatform.deployed()
    })
    .then(i => {
      chronoBankPlatform = i
      return ChronoBankAssetWithFee.deployed()
    })
    .then((instance) => {
      chronoBankAssetWithFee = instance
      return ChronoMint.deployed()
    })
    .then(i => {
      chronoMint = i
    })
    .then(() => {
      return ContractsManager.deployed()
    })
    .then(i => {
      contractsManager = i
    })
    .then(() => {
      return TimeHolder.deployed()
    })
    .then(i => {
      timeHolder = i
      return timeHolder.init(UserStorage.address, ChronoBankAssetProxy.address)
        }).then(function () {
      return timeHolder.addListener(Vote.address)
    })
    .then(() => {
      return ChronoBankPlatformEmitter.deployed()
    })
    .then(i => {
      chronoBankPlatformEmitter = i
      return EventsHistory.deployed()
    })
    .then(i => {
      eventsHistory = i
      return chronoBankPlatform.setupEventsHistory(EventsHistory.address, {
        from: accounts[0],
        gas: 3000000
      })
    })

    .then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitTransfer.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitIssue.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitRevoke.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitOwnershipChange.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitApprove.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitRecovery.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    }).then(() => {
      return eventsHistory.addEmitter(
        chronoBankPlatformEmitter.contract.emitError.getData.apply(this, fakeArgs).slice(0, 10),
        ChronoBankPlatformEmitter.address, paramsGas
      )
    })

    .then(() => {
      return eventsHistory.addVersion(chronoBankPlatform.address, 'Origin', 'Initial version.')
    }).then(() => {
      return chronoBankPlatform
        .issueAsset(SYMBOL, 1000000000000, NAME, DESCRIPTION, BASE_UNIT, IS_NOT_REISSUABLE, paramsGas)
    }).then(r => {
      return chronoBankPlatform.setProxy(ChronoBankAssetProxy.address, SYMBOL, params)
    }).then(r => {
      return ChronoBankAssetProxy.deployed()
    }).then(i => {
      return i.init(ChronoBankPlatform.address, SYMBOL, NAME, params)
    }).then(r => {
      return ChronoBankAssetProxy.deployed()
    }).then(i => {
      return i.proposeUpgrade(ChronoBankAsset.address, params)
    }).then(r => {
      return ChronoBankAsset.deployed()
    }).then(i => {
      return i.init(ChronoBankAssetProxy.address, params)
    }).then(r => {
      return ChronoBankAssetProxy.deployed()
    }).then(i => {
      return i.transfer(ContractsManager.address, 500000000000, params)
    }).then(r => {
      return chronoBankPlatform.changeOwnership(SYMBOL, ContractsManager.address, params)
    }).then(r => {
      return chronoBankPlatform.issueAsset(SYMBOL2, 0, NAME2, DESCRIPTION2, BASE_UNIT, IS_REISSUABLE, {
        from: accounts[0],
        gas: 3000000
      })
    }).then(() => {
      return chronoBankPlatform.setProxy(ChronoBankAssetWithFeeProxy.address, SYMBOL2, params)
    }).then(() => {
      return ChronoBankAssetWithFeeProxy.deployed()
    }).then(i => {
      chronoBankAssetWithFeeProxy = i
      return i.init(ChronoBankPlatform.address, SYMBOL2, NAME2, params)
    }).then(() => {
      return chronoBankAssetWithFeeProxy.proposeUpgrade(ChronoBankAssetWithFee.address, params)
    }).then(() => {
      return chronoBankAssetWithFee.init(ChronoBankAssetWithFeeProxy.address, params)
    }).then(() => {
      return chronoBankAssetWithFee.setupFee(Rewards.address, 100, {from: accounts[0]})
    }).then(function () {
      return chronoBankPlatform.changeOwnership(SYMBOL2, ContractsManager.address, params)
    }).then(() => {
      return chronoBankPlatform.changeContractOwnership(ContractsManager.address, params)
    }).then(() => {
      // return contractsManager.claimPlatformOwnership(ChronoBankPlatform.address, params)
    })

    .then(() => {
      return Exchange.deployed()
    }).then(i => {
      exchange = i
      return exchange.init(ChronoBankAssetWithFeeProxy.address)
    }).then(() => {
      return exchange.changeContractOwnership(contractsManager.address, params)
    }).then(() => {
      // return contractsManager.claimExchangeOwnership(Exchange.address, params)
    }).then(() => {
      return Rewards.deployed()
    }).then(i => {
      rewards = i
      return rewards.init(TimeHolder.address, 0)
    }).then(() => {
      return contractsManager.setOtherAddress(rewards.address, params)
    }).then(() => {
      return contractsManager.setOtherAddress(exchange.address, params)
    }).then(() => {
      return contractsManager.setAddress(ChronoBankAssetProxy.address, params)
    }).then(() => {
      return contractsManager.setAddress(ChronoBankAssetWithFeeProxy.address, params)
    })

    /** EXCHANGE INIT >>> */
    .then(() => {
      // return contractsManager.setExchangePrices(Exchange.address, 1, 2)
    })
    .then(() => {
      return chronoMint.proposeLOC(
        bytes32('Bob\'s Hard Workers'),
        bytes32('www.ru'), 1000,
        bytes32fromBase58('QmTeW79w7QQ6Npa3b1d5tANreCDxF2iDaAPsDvW6KtLmfB'),
        1484554656
      )
    })
    .then(() => {
      return web3.eth.sendTransaction({to: Exchange.address, value: BALANCE_ETH, from: accounts[0]})
    })
    .then(() => {
      exit()
    })
    // .then(r => {
    //   return contractsManager.reissueAsset(SYMBOL2, 2500, r.logs[0].args._LOC, paramsGas)
    // })
    // .then(() => {
    //   return contractsManager.sendAsset(2, Exchange.address, 500, paramsGas)
    // })
    // .then(() => {
    //   return contractsManager.sendAsset(2, accounts[0], 500, paramsGas)
    // })
    /** <<< EXCHANGE INIT */

    .catch(function (e) {
      console.log(e)
    })
}
