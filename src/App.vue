<template>
  <div class="container">
    <div class="b-row">
      <div>
        <h1>
          Auction
          <span>#{{ amount }}</span>
        </h1>
        <hr>
        <div>
          <label for="title">
            Title
          </label>
          <b-form-input
            id="title"
            v-model="title"
            type="text"
            placeholder="title"
          />
        </div>
        <div>
          <label for="startPrice">
            startPrice
          </label>
          <b-form-input
            id="startPrice"
            v-model="startPrice"
            type="text"
            placeholder="start price ETH"
          />
        </div>
        <div>
          <label for="endTime">
            endTime
          </label>
          <b-calendar v-model="endTime" :min="min" :max="max" locale="en"></b-calendar>
        </div>
      </div>
    </div>
    <div class="b-row">
      <div>
        <label for="Description">
          Description
        </label>
        <br>
        <b-form-textarea
          id="Description"
          v-model="description"
          rows="5"
        />
      </div>
    </div>
    <hr>
    <div class="b-row">
      <div>
        <b-button
          :variant="'primary'"
          @click="createAuction"
        >
          {{ createStatus }}
        </b-button>
        <img
          v-show="isLoad"
          src="https://media.giphy.com/media/2A6xoqXc9qML9gzBUE/giphy.gif"
        >
      </div>
    </div>
    <div v-show="isShow">
      <hr>
      <b-card-group
        deck
        v-for="(row,idc) in formattedCards"
        :key="idc"
        class="mb-3"
      >
        <b-card
          v-for="(auctioncard,idx) in row"
          :key="idx"
          :title="auctioncard[0]"
          :sub-title="'Start Price:' + auctioncard[1] + 'ETH'"
          tag="article"
          style="max-width: 29%;"
          class="mb-2"
        >
          <h6 class="card-subtitle text-muted mb-2">Current Price:{{auctioncard[2]}}ETH</h6>
          <h6 class="card-subtitle text-muted mb-2">Your Current Bid:{{auctioncard.yourBid}}ETH</h6>
          <h6 class="card-subtitle text-muted mb-2">Auction Owner:{{auctioncard[7]}}ETH</h6>
          <h6 class="card-subtitle text-muted mb-2">Auction EndTime:{{new Date(Number(auctioncard[8]))}}</h6>
          <h6 v-if="new Date(Number(auctioncard[8])) < new Date()" class="card-subtitle text-muted mb-2"><font color="red">(Ended)</font></h6>
          <hr>
          <p class="card-text, mt-3">
            {{ auctionCardDev[2] }}
          </p>
          <p class="card-text, mt-3">
            Bidders: {{ auctioncard[4] }}
          </p>
          <p class="card-text, mt-3">
            Highest Bidder: {{ auctioncard[3] }}
          </p>
          <p class="card-text, mt-3">
            <br v-if="!auctioncard.highest"><font v-if="auctioncard.highest" color="red">(You are the highest)</font>
          </p>
          <p class="card-text, mt-3">
            Description: {{ auctioncard[5] }}
          </p>
          <div>
            <form @submit.prevent="handleSubmit()">
              <b-input-group v-if="auctioncard[6]==1 && !auctioncard.isOwner">
                <b-form-input
                  v-model="auctioncard.bidPrice"
                />
                <b-input-group-append>
                  <b-button variant="primary" type="submit" @click="currentAuction = idx+idc*3">place BID</b-button>
                  <img
                    v-show="auctioncard.isBid"
                    id="isBid"
                    src="https://media.giphy.com/media/2A6xoqXc9qML9gzBUE/giphy.gif"
                  >
                </b-input-group-append>
              </b-input-group>
            </form>
          </div>
          <b-button
            class="mt-3"
            :variant="'success'"
            @click="currentAuction = idx+idc*3;handleFinalize();"
            :disabled="(auctioncard.isWithDraw == false && auctioncard.isOwner == false) || ((auctioncard[6]==3 || auctioncard[6]==2) && auctioncard.isWithDraw == false)"
            v-if="auctioncard.isOwner || auctioncard[6]!=1"
          >
            {{ (auctioncard[6]==1 && auctioncard.isOwner) ? finalizeStatus: (auctioncard.isWithDraw)?finalize:(auctioncard[6]==3)?"Canceled":"Finalized"}}
          </b-button>
          <img
            v-show="auctioncard.isFin"
            id="isFin"
            src="https://media.giphy.com/media/2A6xoqXc9qML9gzBUE/giphy.gif"
          >
        </b-card>
      </b-card-group>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import web3 from '../contracts/web3';
import auction from '../contracts/auctionInstance';
import auctionBox from '../contracts/auctionBoxInstance';

export default {
  name: 'APP',
  data() {
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    // 15th two months prior
    const minDate = new Date(today)
    // 15th in two months
    const maxDate = new Date(today)
    maxDate.setMonth(maxDate.getMonth() + 2)
    return {
      title: '',
      startPrice: '',
      currentPrice: '',
      endTime: '',
      description: '',
      amount: 0,
      auctionCard: [],
      auctionCardDev: [],
      isShow: false,
      isLoad: false,
      isBid: false,
      isFin: false,
      bidPrice: '',
      auctionAddress: '',
      bidders: 0,
      highestBidder: [],
      currentAuction: '',
      finalizeStatus: 'Cancel',
      finalize: 'WithDraw',
      createStatus: 'CREATE',
      min: minDate,
      max: maxDate
    };
  },
  beforeMount() {
    // get auctionBox method: returnAllAuctions()
    auctionBox.methods
      .returnAllAuctions()
      .call()
      .then(async(auctions) => {
        console.log(auctions);
        // set the amount of auctions
        this.amount = auctions.length;
        for (let index = 0; index < auctions.length; index++) {
            const auctionInstance = auction(auctions[index]);
            let content = await auctionInstance.methods.returnContents().call();
            let bid_content = await auctionInstance.methods.returnYourBid().call({from:ethereum.selectedAddress});
            // console.log(content)
            content[1] = web3.utils.fromWei(content[1], 'ether');
            content[2] = web3.utils.fromWei(content[2], 'ether');
            if(content[3].toLowerCase() == ethereum.selectedAddress) content.highest = true
            content.yourBid = web3.utils.fromWei(bid_content, 'ether');
            content.auctionAddress = auctionInstance.options.address

            content.isOwner = (ethereum.selectedAddress == content[7].toLowerCase())?true:false

            content[6] = (content[6]==1 && content[8] < new Date().getTime())? 2 : content[6]
            content.isWithDraw = (content[6]!=1 && bid_content >0)? true : false
            // console.log(content)
            this.auctionCard.push(content)
            this.isShow = true;

            auctionInstance.events.allEvents()
              .on('data', (event) => {
                console.log(event);
                switch(event.event){
                  case 'PlaceBid':
                  case 'WithDraw':
                  case 'Canceled':
                    this.updateAuctionList()
                    break
                  default:
                    break;
                }
              })
              .on('error', console.error);

            
        }
      })

    auctionBox.events.allEvents()
      .on('data', (event) => {
        console.log(event);
        switch(event.event){
          case 'CreateAuction':
            this.updateAuctionList()
            break
          default:
            break;
        }
      })
      .on('error', console.error);
      
      ethereum.on('accountsChanged', async(accounts) => {
        // for (let index = 0; index < this.auctionCard.length; index++) {
        //   const auctionInstance = auction(this.auctionCard[index].auctionAddress);
        //   let bid_content = await auctionInstance.methods.returnYourBid().call({from:accounts[0]});
        //   console.log(bid_content)
        //   let temp = this.auctionCard[index]
        //   temp.yourBid = web3.utils.fromWei(bid_content, 'ether');
        //   temp.highest = (temp[3].toLowerCase() == ethereum.selectedAddress) ? true : false
        //   Vue.set(this.auctionCard, index, temp)
        // }
        await this.sleep(200)
        await this.updateAuctionList()
      });
  },
  computed: {
      formattedCards() {
          return this.auctionCard.reduce((c, n, i) => {
              if (i % 3 === 0) c.push([]);
              c[c.length - 1].push(n);
              return c;
          }, []);
      }
  },
  methods: {
    createAuction() {
      // get accounts
      web3.eth.getAccounts().then((accounts) => {
        // convert 'ether' to 'wei'
        const startPrice = web3.utils.toWei(this.startPrice, 'ether');
        let endTime = new Date(this.endTime).setHours(0)
        // endTime = endTime.getTime()

        console.log(endTime)
        // createAuction in AuctionBox contract
        this.isLoad = true;
        return auctionBox.methods.createAuction(this.title, startPrice, endTime ,this.description)
          .send({ from: accounts[0] });
      }).then(() => {
        // initialize forms
        this.isLoad = false;
        this.title = '';
        this.startPrice = '';
        this.description = '';
      })

      
    },
    handleSubmit() {
      // convert 'ether' to 'wei'
      const bidPriceWei = web3.utils.toWei(this.auctionCard[this.currentAuction].bidPrice, 'ether');
      // get the wallet adddress
      const fromAddress = web3.eth.accounts.givenProvider.selectedAddress;
      // set the address as the parameter
      const selectedAuction = auction(this.auctionCard[this.currentAuction].auctionAddress);
      this.auctionCard[this.currentAuction].isBid = true;
      console.log(this.currentAuction)
      console.log(this.auctionCard[this.currentAuction].bidPrice)
      // placeBid in Auction contract
      selectedAuction.methods
        .placeBid()
        .send({
          from: fromAddress,
          value: bidPriceWei,
        })
        .then(() => {
          this.auctionCard[this.currentAuction].isBid = false;
        })
    },
    handleFinalize() {
      // get accounts
      web3.eth.getAccounts().then((accounts) => {
        // set the address as the parameter
        const selectedAuction = auction(this.auctionCard[this.currentAuction].auctionAddress);
        this.auctionCard[this.currentAuction].isFin = true;
        // finalizeAuction in Auction contract
        // console.log(this.currentAuction)

        if (this.auctionCard[this.currentAuction][6] == 1 && this.auctionCard[this.currentAuction][7].toLowerCase() == ethereum.selectedAddress) {
          selectedAuction.methods
          .cancelAuction()
          .send({ from: accounts[0] })
          .then(() => {
            this.auctionCard[this.currentAuction].isFin = false;
          });
        } else {
          selectedAuction.methods
          .withDraw()
          .send({ from: accounts[0] })
          .then(() => {
            this.auctionCard[this.currentAuction].isFin = false;
          });
        }
      });
    },
    updateAuctionList() {
      auctionBox.methods.returnAllAuctions().call()
      .then((auctions) => {
        // this.auctionCard = []
        this.amount = auctions.length
        for (let i = 0; i < auctions.length; i++) {
          const element = auctions[i];
          let dup = false
          let index = undefined
          for (let j = 0; j < this.auctionCard.length; j++) {
            const auctionCardElement = this.auctionCard[j];
            if (auctionCardElement.auctionAddress == element) {
              dup = true
              index = j
              break;
            }
          }
          
          // this.auctionAddress = element;
          // set the address as the parameter
          const auctionInstance = auction(element);
          if(!dup){
            auctionInstance.events.allEvents()
              .on('data', (event) => {
                console.log(event);
                switch(event.event){
                  case 'PlaceBid':
                  case 'WithDraw':
                  case 'Canceled':
                    this.updateAuctionList()
                    break
                  default:
                    break;
                }
              })
              .on('error', console.error);
          }
          auctionInstance.methods.returnContents().call()
            .then(async(lists) => {
              const auctionlists = lists;
              let bid_content = await auctionInstance.methods.returnYourBid().call({from:ethereum.selectedAddress});
              // convert 'wei' to 'ether'
              auctionlists[1] = web3.utils.fromWei(lists[1], 'ether');
              auctionlists[2] = web3.utils.fromWei(lists[2], 'ether');

              auctionlists.yourBid = web3.utils.fromWei(bid_content, 'ether');

              auctionlists.auctionAddress = auctionInstance.options.address
              auctionlists.highest = (auctionlists[3].toLowerCase() == ethereum.selectedAddress) ? true : false

              auctionlists.isOwner = (ethereum.selectedAddress == auctionlists[7].toLowerCase())?true:false

              auctionlists[6] = (auctionlists[6]==1 && auctionlists[8] < new Date().getTime())? 2 : auctionlists[6]
              auctionlists.isWithDraw = (auctionlists[6]!=1 && bid_content >0)? true : false
              if(!dup) {
                this.auctionCard.push(auctionlists);
              }else {
                Vue.set(this.auctionCard, index, auctionlists);
              }
              // show up the auction at the bottom of the page
              this.isShow = true;
            })
        }
      })
    },
    sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms))
    },
  }
};
</script>

<style>
#app {
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

h1,
h2 {
  font-weight: normal;
}

ul {
  list-style-type: none;
  padding: 0;
}

li {
  display: inline-block;
  margin: 0 10px;
}

a {
  color: #42b983;
}

button {
  background-color: #008cba;
  color: white;
}

button:hover {
  background-color: white; /* Green */
  color: #008cba;
  border: #008cba 3px solid;
}

img {
  width: 32px;
}

#isBid, #isFin {
  height: 32px;
  margin-top: 16px;
  margin-left: 8px;
}
</style>
