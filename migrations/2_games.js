
const Game = artifacts.require("Chess")
module.exports = async function(deployer , network , accounts){
    await deployer.deploy(Game , 2 , accounts[0] , accounts[1] , web3.utils.toWei("1" , "ether"));
    

}