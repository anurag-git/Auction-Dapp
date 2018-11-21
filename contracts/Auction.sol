/* 
Auction Platform on Blockchain:
All the online auction platforms that currently exist are based on one centralized operation. They rely on proprietary and closed software. As a result of this centralization, these platforms share the same limitations. i.e. Lack of transparency, Closed and Limited.
With blockchain, you will overcome these limitations and build a new auction platform that is open to all, transparent in nature and is peer to peer.

Below are the set of rules that your auction platform will follow. If some rule is missing, assume suitably and sensibly!
1. Owner of an item announces that an item is up for sale, sets the base price and starts the timer.
2. Each bidder has a fixed amount disposable for auction in his/her wallet. Bidder can’t bid more
than the wallet contents.
3. The bidders place their bids in real time and continue participating in the bidding process until
the time is out.
4. Each bid is visible to other bidders real time along with the name/ID of the bidder
5. Once the time is out, the ownership of the item changes to the highest bidder and the item
holds the info of the bid and ownership details.
6. After successful bid, the money from the highest bidder is transferred to the owner of the item.
7. If there is no bidder, mark the item as unsold.
8. Each participant in the ecosystem can be an owner or a bidder (not both at once).
Stakeholders:
1. Owner
2. Bidders
*/

pragma solidity ^0.4.24;

contract Auction {
    // Parameters of the auction. Times are either
    // absolute unix timestamps (seconds since 1970-01-01)
    // or time periods in seconds.
    address public owner;
    uint private auctionEndTime;

    // Current state of the auction.
    address private highestBidder;
    uint private highestBid;

    // Allowed withdrawals of previous bids
    mapping(address => uint) private pendingReturns;

    mapping(address => Item) private itemList;
    mapping(address => uint) private accountBalances;

    struct Item {
        string itemName;
        address itemOwner;
        uint itemID;
        uint itemBasePrice;
        address itemHighestBidder;
        uint itemHighestBidAmount;
        string itemStatus;
    }

    uint private uniqueID=1;

    // Events that will be fired on changes.
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Auction states to control function calls
    enum AuctionState {
        NotStarted,
        Started,
        Ended
    }

    // Ideally state variable should be private but
    // needed to make it public so that I can access it in truffle test cases
    // Another way is to make this variable private and create a public getter function
    // to get the current Auction State
    AuctionState public state;

    modifier inState(AuctionState _state) {
        require(state == _state, "Please check the required state for this activity!!!");
        _;
    }

    modifier isOwner {
        require(msg.sender == owner,"You are not an owner");
        _;
    }

    modifier isNotOwner {
        require(msg.sender != owner,"You are an owner");
        _;
    }

    // The following is a so-called natspec comment, recognizable by the three slashes.
    // It will be shown when the user is asked to confirm a transaction.

    /// Create a simple auction with `_biddingTime` seconds bidding time
    /// on behalf of the beneficiary address `_beneficiary`.
    constructor() public {
        state = AuctionState.NotStarted;
    }

    // Needed to add this reset function, as
    // only first truffle test which changes state works but after that it is not working.
    // Ideally, every truffle test case run in clean environment.
    // TODO: Remove this function and make truffle tests work without the use of this function

    function resetState() public {
        state = AuctionState.NotStarted;
        highestBid = 0;
        highestBidder = address(0x0);
    }

    function auctionStart(uint _biddingTime, string _itemName, uint _basePrice) public inState(AuctionState.NotStarted) {
        owner = msg.sender;
        auctionEndTime = now + _biddingTime;

        Item memory newItem = Item({
           itemName: _itemName,
           itemOwner: owner,
           itemID: uniqueID,
           itemBasePrice: _basePrice,
           itemHighestBidder: address(0x0),  // initially nobody is owner, hence setting to "0" address
           itemHighestBidAmount: 0,
           itemStatus: "Not Sold" // initially item is "Not Sold", if nobody bids it remains unsold else it gets sold to highest bidder.
        });

        uniqueID++;
        itemList[owner] = newItem;
        state = AuctionState.Started;
    }

    /// Bid on the auction with the value sent together with this transaction.
    /// The value will only be refunded if the auction is not won.
    function bid() public payable isNotOwner inState(AuctionState.Started)  {
        // Revert the call if the bidding period is over.
        require(now <= auctionEndTime,"Auction already ended.");

        Item memory bidItem = itemList[owner];
        require(msg.value > bidItem.itemBasePrice, "Bid should be greater than Base Price");

        /*
        TODO:
        Tried below commented code for Point 2 but didn't work for me.
        Need to relook at it.
        2. Each bidder has a fixed amount disposable for auction in his/her wallet. Bidder can’t bid more
        than the wallet contents.
        ==>Not able to implement this scenario, tried few ideas like
        taking the balances of all accounts and adding it in a mapping, but it didn't work.

        However, getBalance() of any account returns current account balances
        but same code doesn't add the balance to mapping against the particular owner.
        */

        // storing account balance of each bidder
        //accountBalances[msg.sender] = address(msg.sender).balance;
        //require(msg.value > accountBalances[msg.sender],"Not sufficient balance to bid");

        // If the bid is not higher, send the money back.
        require(msg.value > highestBid,"There already is a higher bid.");

        if (highestBid != 0) {
            // Sending back the money by simply using highestBidder.send(highestBid) is a security risk because it could execute an untrusted contract.
            // It is always safer to let the recipients withdraw their money themselves.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        bidItem.itemHighestBidder = highestBidder;

        highestBid = msg.value;
        bidItem.itemHighestBidAmount = highestBid;

        itemList[owner] = bidItem;

        // decrease account balance after successful bid
        //accountBalances[msg.sender] -= msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdrawPendingAmount() isNotOwner public returns (bool) {
          require(now >= auctionEndTime, "Auction not yet ended.");
        /// Withdraw a bid that was overbid.
          // anyone who participated but did not win the auction should be allowed to withdraw
          // the full amount of their funds
          uint amount = pendingReturns[msg.sender];
          require(amount > 0,"No pending amount");
          // It is important to set this to zero because the recipient
          // can call this function again as part of the receiving call before `send` returns.
          pendingReturns[msg.sender] = 0;

          if (!msg.sender.send(amount)) {
              // No need to call throw here, just reset the amount owing
              pendingReturns[msg.sender] = amount;
              return false;
          }
          return true;

          /* TODO:
            We could emit Withdraw event, realize a  bit late for implementing and testing
          */
    }

    /// End the auction and send the highest bid to the owner.
    function withdrawBidAmount() isOwner inState(AuctionState.Started) public {
        // 1. Conditions
      require(now >= auctionEndTime, "Auction not yet ended.");

        // 2. Effects
        state = AuctionState.Ended;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        // change item owner after auction expires, and mark it as sold
        Item memory bidItem = itemList[owner];
        bidItem.itemOwner = highestBidder;
        bidItem.itemStatus = "Sold";

        itemList[owner] = bidItem;

        owner.transfer(highestBid);
    }

    function getItemData(address _owner) public view returns (string,address,uint,uint,address,uint,string) {
        Item memory tempItem = itemList[_owner];
        return (
          tempItem.itemName,
          tempItem.itemOwner,
          tempItem.itemID,
          tempItem.itemBasePrice,
          tempItem.itemHighestBidder,
          tempItem.itemHighestBidAmount,
          tempItem.itemStatus
        );
    }

    function getBalance() public view returns(uint) {
      return address(msg.sender).balance;
    }
}
