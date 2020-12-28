// We will be using Solidity version 0.5.3
pragma solidity 0.6.0;
// Importing OpenZeppelin's SafeMath Implementation
import "./SafeMath.sol";

contract AuctionBox{
    Auction[] public auctions; 

    event CreateAuction(address auctionAddress, string tilte, uint256 time);
   
    function createAuction (
        string memory _title,
        uint _startPrice,
        uint _endTime,
        string memory _description
        ) public{
        require(_startPrice > 0);
        // set the new instanc
        Auction newAuction = new Auction(msg.sender, _title, _startPrice, _endTime ,_description);
        // push the auction address to auctions array
        auctions.push(newAuction);
        emit CreateAuction(address(newAuction), _title ,now);
    }
    
    function returnAllAuctions() public view returns(Auction[] memory){
        return auctions;
    }
}

contract Auction {
    using SafeMath for uint256;
    
    address payable private owner; 
    string title;
    uint startPrice;
    string description;
    uint endTime;

    enum State{Default, Running, Finalized, Canceled}
    State public auctionState;

    uint public highestPrice;
    address payable public highestBidder;
    uint256 public bidders = 1;
    mapping(address => uint) public bids;

    event PlaceBid(address sender, uint256 value, uint256 time);

    event WithDraw(address sender, uint256 time);

    event Canceled(uint256 time);
    
    /** @dev constructor to creat an auction
      * @param _owner who call createAuction() in AuctionBox contract
      * @param _title the title of the auction
      * @param _startPrice the start price of the auction
      * @param _description the description of the auction
      */
      
    constructor(
        address payable _owner,
        string memory _title,
        uint _startPrice,
        uint _endTime,
        string memory _description
        
        ) public {
        // initialize auction
        owner = _owner;
        title = _title;
        highestPrice = startPrice = _startPrice;
        highestBidder = _owner;
        description = _description;
        endTime = _endTime;
        auctionState = State.Running;
    }
    
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    /** @dev Function to place a bid
      * @return true
      */
    
    function placeBid() public payable notOwner returns(bool) {
        require(auctionState == State.Running);
        require(now.mul(1000) <= endTime);
        require(msg.value > 0);
        // update the current bid
        // uint currentBid = bids[msg.sender] + msg.value;
        uint currentBid = bids[msg.sender].add(msg.value);
        require(currentBid > highestPrice);
        if(currentBid.sub(msg.value) == 0) bidders = bidders.add(1);

        // set the currentBid links with msg.sender
        bids[msg.sender] = currentBid;
        // update the highest price
        highestPrice = currentBid;
        highestBidder = msg.sender;

        emit PlaceBid(msg.sender,msg.value,now);
        
        return true;
    }
    
    function withDraw() public{
        //the owner and bidders can finalize the auction.
        require(msg.sender == owner || bids[msg.sender] > 0);
        
        address payable recipiant;
        uint value;

        if(auctionState == State.Canceled){
            recipiant = msg.sender;
            value = bids[msg.sender];
        }else{
            // owner can get highestPrice
            if(msg.sender == owner){
                recipiant = owner;
                value = highestPrice;
            }
            // highestBidder can get no money
            else if (msg.sender == highestBidder){
                recipiant = highestBidder;
                value = 0;
            }
            // Other bidders can get back the money 
            else {
                recipiant = msg.sender;
                value = bids[msg.sender];
            }
        }
        
        
        // initialize the value
        bids[msg.sender] = 0;
        recipiant.transfer(value);
        // auctionState = State.Finalized;

        emit WithDraw(msg.sender, now);
    }

    function returnYourBid() public view returns( uint ){
        return bids[msg.sender];
    }

    function cancelAuction()
        public returns (bool success)
    {
        require(msg.sender == owner);
        require(now.mul(1000) <= endTime);
        auctionState = State.Canceled;
        emit Canceled(now);
        return true;
    }
    
    /** @dev Function to return the contents od the auction
      * @return the title of the auction
      * @return the start price of the auction
      * @return the description of the auction
      * @return the state of the auction 
      */    
    
    function returnContents() public view returns(        
        string memory,
        uint,
        uint,
        address,
        uint,
        string memory,
        State,
        address,
        uint
        ) {
        return (
            title,
            startPrice,
            highestPrice,
            highestBidder,
            bidders,
            description,
            auctionState,
            owner,
            endTime
        );
    }
    
}