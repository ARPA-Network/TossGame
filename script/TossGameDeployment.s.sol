// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {TossGame} from "../src/TossGame.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAdapter} from "Randcast-User-Contract/interfaces/IAdapter.sol";

contract TossGameDeployment is Script {
    function run() external {
        IAdapter adapter;
        TossGame tossGameImpl;
        ERC1967Proxy tossGameProxy;
        TossGame tossGame;

        uint256 plentyOfEthBalance = vm.envUint("SUB_FUND_ETH_BAL");
        address adapterAddress = vm.envAddress("ADAPTER_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address deployedTokenAddress = vm.envAddress("DEPLOYED_TOKEN_ADDRESS");

        adapter = IAdapter(adapterAddress);

        vm.startBroadcast(deployerPrivateKey);
        tossGameImpl = new TossGame();

        tossGameProxy = new ERC1967Proxy(
            address(tossGameImpl), abi.encodeWithSignature("initialize(address,address)", adapterAddress, operator)
        );

        tossGame = TossGame(address(tossGameProxy));

        // Add token support
        tossGame.addSupportedToken(deployedTokenAddress);

        // Add ETH support
        tossGame.addSupportedToken(address(0));

        // set TossFeeBPS
        tossGame.setTossFeeBPS(250);

        // Fund subscription
        uint64 subId = tossGame.getContractSubId();

        adapter.fundSubscription{value: plentyOfEthBalance}(subId);

        vm.stopBroadcast();
    }
}
