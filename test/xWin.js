const WINTOKEN = artifacts.require('./xWinToken.sol')
const xWinTimeLockVault = artifacts.require('./xWinTimeLockVault.sol')
const xWinMaster = artifacts.require('./xWinMaster.sol')
const xWinDefi = artifacts.require('./xWinDefi.sol')
const xWinFund = artifacts.require('./xWinFund.sol')
const SampleToken1 = artifacts.require('./SampleToken.sol')
const SampleTokenBTC = artifacts.require('./SampleTokenBTC.sol')
const Mock = artifacts.require('./Mock.sol')


require('chai')
  .use(require('chai-as-promised'))
  .should()

contract('XWIN Token', ([deployer, fundmanager, investor1, token1, token2, token3]) => {
  
    let wintoken
    let xwinTLV
    let xwinMasterJS
    let xwinDefiJS
    let xwinFundJS
    let token1JS
    let token2JS
    let mockJS
    
    before(async () => {
        token1JS = await SampleToken1.deployed()
    })
    before(async () => {
        token2JS = await SampleTokenBTC.deployed()
    })
    before(async () => {
        wintoken = await WINTOKEN.deployed()
    })
    before(async () => {
        xwinTLV = await xWinTimeLockVault.deployed()
    })
    before(async () => {
        xwinMasterJS = await xWinMaster.deployed()
    })
    before(async () => {
        xwinDefiJS = await xWinDefi.deployed()
    })
    before(async () => {
        xwinFundJS = await xWinFund.deployed()
    })
    before(async () => {
        mockJS = await Mock.deployed()
    })

    describe('SampleToken1 Transfer to Mock', async () => {
        it('transfer SampleToken1', async () => {
            token1JS.transfer(mockJS.address, web3.utils.toBN(10*(10**18)));
            const bal = await token1JS.balanceOf(mockJS.address)
            assert.equal(bal, "10000000000000000000")
        })
    })

    describe('SampleTokenBTC Transfer to Mock', async () => {
        it('transfer SampleTokenBTC', async () => {
            token2JS.transfer(mockJS.address, web3.utils.toBN(10*(10**18)));
            const bal2 = await token2JS.balanceOf(mockJS.address)
            assert.equal(bal2, "10000000000000000000")
        })
    })

    describe('deployment xWinToken', async () => {
        it('deploys xWinToken successfully', async () => {
        let WINTokenaddress = await wintoken.address
        const balance = await wintoken.balance
        assert.notEqual(WINTokenaddress, 0x0)
        assert.notEqual(WINTokenaddress, '')
        assert.notEqual(WINTokenaddress, null)
        assert.notEqual(WINTokenaddress, undefined)
        })

        it('has a name', async () => {
        const name = await wintoken.name()
        const maxCap = await wintoken.maxCap()
        const bal = await wintoken.balanceOf(deployer)
        assert.equal(name, 'xWIN Token')
        assert.equal(maxCap, "100000000000000000000")
        assert.equal(bal, 0)
        })

        it('max supply', async () => {
            const maxCap = await wintoken.maxCap()
            assert.equal(maxCap, "100000000000000000000")
        })

        it('add mint role', async () => {
            let isMintUser = await wintoken.isMintUser(deployer)
            assert.equal(isMintUser, false)
            await wintoken.addMintUser(deployer)
            isMintUser = await wintoken.isMintUser(deployer)
            assert.equal(isMintUser, true)
        })

        it('mint XWIN', async () => {
            
            await wintoken.mint(investor1, web3.utils.toBN(10*(10**18)))
            await wintoken.mint(deployer, web3.utils.toBN(10*(10**18)))
            await wintoken.mint(xwinDefiJS.address, web3.utils.toBN(50*(10**18)))
            let bal = await wintoken.balanceOf(deployer)
            assert.equal(bal, "10000000000000000000")
        })
    })

    describe('deployment xWinTimeLockVault', async () => {
        it('deploys xWinTimeLockVault successfully', async () => {
            let xwinTLVaddress = await xwinTLV.address
            assert.notEqual(xwinTLV, 0x0)
            assert.notEqual(xwinTLV, '')
            assert.notEqual(xwinTLV, null)
            assert.notEqual(xwinTLV, undefined)
        })

        it('has a name', async () => {
            const name = await xwinTLV.name()
            assert.equal(name, 'xWin Team Vault')
        })

        it('GetEstimateReclaimToken', async () => {
            await wintoken.mint(xwinTLV.address, web3.utils.toBN(10*(10**18)))
            const estimateToken = await xwinTLV.GetEstimateReclaimToken()
            assert.equal(estimateToken, 10000000000000000000)
        })

        it('ReclaimXWNToken', async () => {
            await xwinTLV.ReclaimXWNToken(fundmanager)
            const bal = await wintoken.balanceOf(fundmanager)
            assert.equal(bal, 10000000000000000000)
        })

    })

    describe('deployment xWinMaster', async () => {
        it('deploys xWinMaster successfully', async () => {
            let xWinMasteraddress = await xwinMasterJS.address
            assert.notEqual(xwinMasterJS, 0x0)
            assert.notEqual(xwinMasterJS, '')
            assert.notEqual(xwinMasterJS, null)
            assert.notEqual(xwinMasterJS, undefined)
        })

        it('has a name', async () => {
            const name = await xwinMasterJS.name()
            assert.equal(name, 'xWin Master')
        })

        it('getPriceFromBand', async () => {
            const price = await xwinMasterJS.getPriceFromBand("BTC", "ETH")
            assert.equal(price, '1000000000000000000')
        })

        it('updateTokenNames and getTokenName', async () => {
            await xwinMasterJS.updateTokenNames([token1JS.address, token2JS.address], ["ETH", "BTC"])
            const tokenname = await xwinMasterJS.getTokenName(token1JS.address)
            const tokenname2 = await xwinMasterJS.getTokenName(token2JS.address)
            assert.equal(tokenname, "ETH")
            assert.equal(tokenname2, "BTC")
        })

        it('addPancakePriceToken', async () => {
            await xwinMasterJS.addPancakePriceToken(["FROG"], [token3])
            const usePCPrice = await xwinMasterJS.pancakePriceToken(token3)
            const usePCPrice2 = await xwinMasterJS.pancakePriceToken(token1)
            assert.equal(usePCPrice, true)
            assert.equal(usePCPrice2, false)
        })
    })

    describe('deployment xWinDefi - Farming ', async () => {
         it('deploys xWinDefi successfully', async () => {
            let xWinDefiaddress = await xwinDefiJS.address
            assert.notEqual(xwinDefiJS, 0x0)
            assert.notEqual(xwinDefiJS, '')
            assert.notEqual(xwinDefiJS, null)
            assert.notEqual(xwinDefiJS, undefined)
        })

        it('has a name', async () => {
            const name = await xwinDefiJS.name()
            assert.equal(name, 'xWinDefi Protocol')
        })

        it('add pool', async () => {
            await xwinDefiJS.add(wintoken.address, 10000000000, 200)
            const poolInfo = await xwinDefiJS.poolInfo(0)
            assert.equal(poolInfo.lpToken, wintoken.address)
            assert.equal(poolInfo.rewardperblock, 10000000000)
            assert.equal(poolInfo.multiplier, 200)
        })

        it('DepositFarm', async () => {
            await wintoken.approve(xwinDefiJS.address, web3.utils.toBN(100*(10**18)), {from: fundmanager})
            const result = await xwinDefiJS.DepositFarm(0, web3.utils.toBN(1*(10**18)), {from: fundmanager})
        })
        it('DepositFarm 2', async () => {
            await wintoken.approve(xwinDefiJS.address, web3.utils.toBN(10*(10**18)), {from: investor1})
            const result = await xwinDefiJS.DepositFarm(0, web3.utils.toBN(1*(10**18)), {from: investor1})
        })
        it('pendingXwin', async () => {
            const currentRealizedQty = await xwinDefiJS.pendingXwin(0, fundmanager)
            assert.equal(currentRealizedQty, "40000000000")
        })
        it('WithdrawFarm', async () => {
            const result = await xwinDefiJS.WithdrawFarm(0, web3.utils.toBN(1*(10**18)), {from: fundmanager})
            let bal = await wintoken.balanceOf(fundmanager)
            assert.equal(web3.utils.fromWei(bal.toString()), '10.00000006')
        })

        it('emergencyWithdraw', async () => {
            //on the emergency
            await xwinDefiJS.updateEmergencyState(true, {from: deployer})
            const result = await xwinDefiJS.emergencyWithdraw(0, {from: investor1})
            //const event = result.logs[0].args
            //assert.equal(event.amount, '1000000000000000000')
            //off the emergency
            //await xwinDefiJS.updateEmergencyState(false, {from: deployer})
        })

        it('updateEmergencyState', async () => {
            //on the emergency
            await xwinDefiJS.updateEmergencyState(false, {from: deployer})
            let emergencyOn = await xwinDefiJS.emergencyOn()
            assert.equal(emergencyOn, false)
        })

        
    })

    describe('deployment xWinFund', async () => {
         it('deploys xWinFund successfully', async () => {
            let xWinFundaddress = await xwinFundJS.address
            assert.notEqual(xwinFundJS, 0x0)
            assert.notEqual(xwinFundJS, '')
            assert.notEqual(xwinFundJS, null)
            assert.notEqual(xwinFundJS, undefined)
        })

        it('has a name', async () => {
            const name = await xwinFundJS.name()
            assert.equal(name, 'Test Fund')
        })

        it('getLatestPrice', async () => {
            const price = await xwinFundJS.getLatestPrice(token1JS.address)
            assert.equal(price, '1000000000000000000')
        })

        it('getTokenValues', async () => {
            const tokenvalue = await xwinFundJS.getTokenValues(token1JS.address)
            assert.equal(tokenvalue, '0')
        })

        it('getFundValues', async () => {
            const fundvalue = await xwinFundJS.getFundValues()
            assert.equal(fundvalue, '0')
        })

    })

    describe('xWinFund and xWinDefi Related ', async () => {
        it('CreateTarget from xWinDefi', async () => {
            const result =  await xwinDefiJS.CreateTarget(
                    [token1JS.address, token2JS.address], 
                    ["6000", "4000"], 
                    xwinFundJS.address, {from: fundmanager}
                )
            const weight = await xwinFundJS.getTargetWeight(token1JS.address)
            assert.equal(weight, "6000")
            const weight2 = await xwinFundJS.getTargetWeight(token2JS.address)
            assert.equal(weight2, "4000")
        })

        it('Subscribe from xWinDefi investor1', async () => {
            let tradeParam1 = {
                xFundAddress: xwinFundJS.address,
                amount : '2000000000000000000',
                priceImpactTolerance : 10000000,
                deadline : Math.floor(Date.now() / 1000) + 60 * 15,
                returnInBase : true,
                referral: fundmanager
              }
             
            const result1 =  await xwinDefiJS.Subscribe(tradeParam1, {from: investor1, value: web3.utils.toBN(2*(10**18))})
            const event = result1.logs[1].args
            assert.equal(event.mintQty, '2000000000000000000')
        })

        it('Subscribe from xWinDefi manager', async () => {
            let tradeParam1 = {
                xFundAddress: xwinFundJS.address,
                amount : '1000000000000000000',
                priceImpactTolerance : 10000000,
                deadline : Math.floor(Date.now() / 1000) + 60 * 15,
                returnInBase : true,
                referral: investor1
              }
              
            const result1 =  await xwinDefiJS.Subscribe(tradeParam1, {from: fundmanager, value: web3.utils.toBN(1*(10**18))})
            const event = result1.logs[1].args
            assert.equal(event.mintQty, '1000000000000000000')
        })

        it('xWinRewards investor1', async () => {
            const reward =  await xwinDefiJS.xWinRewards(investor1)
            assert.equal(web3.utils.fromWei(reward.accBasetoken.toString()), '2')
            assert.equal(web3.utils.fromWei(reward.accMinttoken.toString()), '2')
            assert.equal(web3.utils.fromWei(reward.previousRealizedQty.toString()), '0.1')
        })

        it('xWinRewards fundmanager', async () => {
            const reward =  await xwinDefiJS.xWinRewards(fundmanager)
            assert.equal(web3.utils.fromWei(reward.accBasetoken.toString()), '1')
            assert.equal(web3.utils.fromWei(reward.accMinttoken.toString()), '1')
            assert.equal(web3.utils.fromWei(reward.previousRealizedQty.toString()), '0.15')
        })

        it('Redeem from xWinDefi investor1', async () => {
            
            await xwinFundJS.approve(xwinDefiJS.address, web3.utils.toBN(100*(10**18)), {from: investor1})
            let tradeParam1 = {
                xFundAddress: xwinFundJS.address,
                amount : '1000000000000000000',
                priceImpactTolerance : 10000000,
                deadline : Math.floor(Date.now() / 1000) + 60 * 15,
                returnInBase : true,
                referral: fundmanager
              }
              
            const result1 =  await xwinDefiJS.Redeem(tradeParam1, {from: investor1, value: 0})
            const event = result1.logs[0].args
            //console.log(event.rewardQty.toString())
            assert.equal(event.rewardQty, '100002853881278530')
        })

        it('getBalance', async () => {
            const bal = await xwinFundJS.getBalance(token1JS.address)
            const bal2 = await xwinFundJS.getBalance(token2JS.address)
            const weight = await xwinFundJS.getTargetWeight(token1JS.address)
            assert.equal(web3.utils.fromWei(bal.toString()), "2")
            assert.equal(web3.utils.fromWei(bal2.toString()), "2")
            assert.equal(weight, "6000")
        })
        
        it('MoveNonIndexNameToBase from xWinDefi By Manager', async () => {
            const deadline = Math.floor(Date.now() / 1000) + 60 * 15
            const result1 =  await xwinDefiJS.MoveNonIndexNameToBase(xwinFundJS.address, token1JS.address, deadline, 10000000, {from: fundmanager, value: 0})
            const event = result1.logs[0].args
            assert.equal(event.amount, "2000000000000000000")
            assert.equal(event.swapOutput, "1")
        })

        it('Rebalance from xWinDefi', async () => {
            
            let tradeParam1 = {
                xFundAddress: xwinFundJS.address,
                amount : '0',
                priceImpactTolerance : 10000000,
                deadline : Math.floor(Date.now() / 1000) + 60 * 15,
                returnInBase : true,
                referral: fundmanager
              }
              
            const result1 =  await xwinDefiJS.RebalanceAllInOne(
                tradeParam1, 
                [token1JS.address, token2JS.address], 
                ["1000", "9000"], {from: fundmanager, value: 0})
            const event = result1.logs[0].args
            assert.equal(event.baseBalance, '0')
            const weight = await xwinFundJS.getTargetWeight(token1JS.address)
            assert.equal(weight, "1000")
            const weight2 = await xwinFundJS.getTargetWeight(token2JS.address)
            assert.equal(weight2, "9000")
        })
    })
})