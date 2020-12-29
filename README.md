# Auction

## Modified
* 以[https://github.com/openberry-ac/Auction/](https://github.com/openberry-ac/Auction/) 基底修改
* 新增部分
    * 前端部分
        * 可根據鍊上變化即時更新拍賣顯示狀態
        * Refresh頁面也能獲取所有拍賣狀態而不會消失
        * 完善介面操作及狀態顯示邏輯
    * 合約部分
        * 取消拍賣功能
        * 拍賣結束時間

## Requirement
* ganache-cli
* npm install truffle -g
* npm install --dev
* MetaMask browser extension
* 複製ganache-cli中之private key新增至MetaMask中


## Deploy
* 更改truffle-config.js 中networks之development成要部署之node url (ganache預設為 http://localhost:8545)
* truffle migrate --reset
* 取代 contracts/auctionBoxInstance.js 中之address為上一步中Deploying 'AuctionBox'中之contract address
* 取代 contracts/auctionBoxInstance.js 中之abi為 build/contracts/AuctionBox.json中之abi
* 取代 contracts/auctionInstance.js 中之abi為 build/contracts/Auction.json中之abi

## Test
* npm run dev
* [localhost:8080](http://localhost:8080)