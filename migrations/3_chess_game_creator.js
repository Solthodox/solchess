const gameCreator = artifacts.require("ChessGameCreator")
const game = artifacts.require("Chess")
module.exports = async function(deployer , network , accounts){
    await deployer.deploy(gameCreator);
    const gamecreator = await gameCreator.deployed()
    await gamecreator.createPrivateGame("Prueba" , accounts[0] , accounts[1] , web3.utils.toWei("2" , "ether"))
    const lobbies = await gamecreator.lobbies()
    const lobbyAddress = lobbies[0].gameAddress
    const current = await game.at(lobbyAddress)
    console.log (current.address)

}