const Auction = artifacts.require("Auction");

contract("Auction Contract", accounts => {
  const ownerAccount = accounts[0];
  const account1 = accounts[1];
  const account2 = accounts[2];
  const account3 = accounts[3];

  let instance;

  beforeEach(async () => {
      //BeforeEach will be called before each "it" function
      //So do whatever is common to all "it", which has to be
      //done before calling "it"

      //Deploy the contract with the specified value
      instance = await Auction.new({from: ownerAccount});

    });

  it("Checking Initial Smart Contract state", async () => {
    let state = await instance.state.call();
    let state_1 = state.toNumber();
    // state should be "Not Started" i.e "0" as it is enum
    assert.equal(state_1, 0, 'State is not equal to "Not Started"');
  });

  it("Auction Success Flow", async () => {
    // Start the Auction, aurction time is 2 secs
    await instance.auctionStart(2, "aa", 100);

    let owner = await instance.owner.call();
    assert.equal(owner, ownerAccount, "Not an owner account");

    /*
    let [
      itemName,
      itemOwner,
      uniqueID,
      basePrice,
      highestBidder,
      highestBid,
      itemStatus
    ] = await instance.getItemData(owner);
    console.log(
      "ItemName=" +
        itemName +
        "\n" +
        "ItemOwner=" +
        itemOwner +
        "\n" +
        "Unique ID=" +
        uniqueID.toNumber() +
        "\n" +
        "Baseprice=" +
        basePrice.toNumber() +
        "\n" +
        "Highest Bidder=" +
        highestBidder +
        "\n" +
        "Highest Bid=" +
        highestBid.toNumber() +
        "\n" +
        "ItemStatus=" +
        itemStatus +
        "\n"
    );
*/
    let state = await instance.state.call();
    let state_1 = state.toNumber();
    // state should be "Started" i.e."1" as it is enum
    assert.equal(state_1, 1, 'State is not equal to "Started"');

    // Start Bidding
    // Account1 Bids
    await instance.bid({
      from: account1,
      value: web3.toWei(1, "ether")
    });

    /*
    let [, , , , highestBidder1, highestBid1] = await instance.getItemData(
      owner
    );
    console.log(
      "Highest Bidder1=" +
        highestBidder1 +
        "\n" +
        "Highest Bid1=" +
        highestBid1.toNumber()
    );
*/
    //Account2 Bids
    await instance.bid({ from: account2, value: web3.toWei(2, "ether") });

    /*
    let [, , , , highestBidder2, highestBid2] = await instance.getItemData(
      owner
    );
    console.log(
      "Highest Bidder2=" +
        highestBidder2 +
        "\n" +
        "Highest Bid2=" +
        highestBid2.toNumber()
    );
*/
    //Account3 Bids
    await instance.bid({ from: account3, value: web3.toWei(3, "ether") });

    /*
    let [, , , , highestBidder31, highestBid31] = await instance.getItemData(
      owner
    );
    console.log(
      "Highest Bidder31=" +
        highestBidder31 +
        "\n" +
        "Highest Bid31=" +
        highestBid31.toNumber()
    );
*/

    //Account3 Bids
    await instance.bid({ from: account3, value: web3.toWei(4, "ether") });

    /*
    let [, , , , highestBidder3, highestBid3] = await instance.getItemData(
      owner
    );
    console.log(
      "Highest Bidder3=" +
        highestBidder3 +
        "\n" +
        "Highest Bid3=" +
        highestBid3.toNumber()
    );
*/
    let ownerBalOld = web3.fromWei(web3.eth.getBalance(owner), "ether");
    let bal1 = web3.toWei(ownerBalOld, "ether").toNumber();

    let excep;

    // sleep for 10 secs so that auction times out.
    function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function demo() {
      //    console.log("Taking a break till auction times out...");
      await sleep(10000);
      //    console.log("Ten seconds later");
    }

    demo();
    // withdraw bid amount
    try {
      excep = false;
      await instance.withdrawBidAmount({ from: ownerAccount });
    } catch (err) {
      excep = true;
    }
    assert.equal(excep, false);

    let ownerBalNew = web3.fromWei(web3.eth.getBalance(owner), "ether");
    let bal2 = web3.toWei(ownerBalNew, "ether").toNumber();

    /*
    let [
      ,
      itemOwner4,
      ,
      ,
      highestBidder4,
      highestBid4,
      itemStatus4
    ] = await instance.getItemData(owner);
    console.log(
      "\n" +
        "New Item Owner=" +
        itemOwner4 +
        "\n" +
        "Item Status=" +
        itemStatus4
    );
*/
    try {
      excep = false;
      await instance.withdrawPendingAmount({ from: account1 });
    } catch (err) {
      excep = true;
    }
    assert.equal(excep, false);

    try {
      excep = false;
      await instance.withdrawPendingAmount({ from: account2 });
    } catch (err) {
      excep = true;
    }
    assert.equal(excep, false);

    try {
      excep = false;
      await instance.withdrawPendingAmount({ from: account3 });
    } catch (err) {
      excep = true;
    }
    assert.equal(excep, false);
  });

  it("Bid should be greater than base Price", async () => {
    // Start the Auction, auction time is 2 secs
    await instance.auctionStart(2, "aa", 100);
    try {
      await instance.bid({ from: account1, value: 55 });
      assert(false);
    } catch (err) {
      assert(err);
    }
  });

  it("Bid should be greater than highest bid", async () => {
    let owner = await instance.owner.call();
    // Start the Auction, aurction time is 2 secs
    await instance.auctionStart(2, "aa", 100);
    await instance.bid({ from: account1, value: 101 });

    try {
      await instance.bid({ from: account2, value: 101 });
      assert(false);
    } catch (err) {
      assert(err);
    }

    /*
    let [
      itemName,
      itemOwner,
      uniqueID,
      basePrice,
      highestBidder,
      highestBid,
      itemStatus
    ] = await instance.getItemData(owner);
    console.log(
      "ItemName=" +
        itemName +
        "\n" +
        "ItemOwner=" +
        itemOwner +
        "\n" +
        "Unique ID=" +
        uniqueID.toNumber() +
        "\n" +
        "Baseprice=" +
        basePrice.toNumber() +
        "\n" +
        "Highest Bidder=" +
        highestBidder +
        "\n" +
        "Highest Bid=" +
        highestBid.toNumber() +
        "\n" +
        "ItemStatus=" +
        itemStatus +
        "\n"
    );
*/
  });

  it("Attempt to withdraw Bid amount before auction ends", async () => {
    let owner = await instance.owner.call();
    // Start the Auction, aurction time is 2 secs
    await instance.auctionStart(10, "aa", 100);
    await instance.bid({ from: account1, value: 101 });

    let excep;
    try {
      excep = false;
      await instance.withdrawBidAmount({ from: ownerAccount });
    } catch (err) {
      excep = true;
    }

    // withdraw will fail and throw exception as called before auction ends.
    assert.equal(excep, true);
  });

  it("Attempt to withdraw Pending amount before auction ends", async () => {
    let owner = await instance.owner.call();
    // Start the Auction, aurction time is 2 secs
    await instance.auctionStart(10, "aa", 100);
    await instance.bid({ from: account1, value: 101 });

    let excep;
    try {
      excep = false;
      await instance.withdrawPendingAmount({ from: account1 });
    } catch (err) {
      excep = true;
    }

    // withdraw will fail and throw exception as called before auction ends.
    assert.equal(excep, true);
  });
});
