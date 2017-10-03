pragma solidity ^0.4.8;

import "./StandardToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./oraclizeAPI.sol";


contract CoinsOpenToken is StandardToken, usingOraclize, Ownable
{

  /*
  Inherited functions:
    Ownable:
    -onlyOwner
    -transferOwnership

  */

  // Token informations
  string public constant name = "COT";
  string public constant symbol = "COT";
  uint8 public constant decimals = 18;
  uint public totalSupply = 21000000 * decimals;
  uint256 public presaleSupply = 2000000  * decimals;
  uint256 public saleSupply = 12000000 * decimals;
  uint256 public reserveSupply = 7000000 * decimals;

  uint256 public saleStartTime = 0;
  uint256 public saleEndTime = 0;
  uint256 public preSaleEndTime = 0;

  uint256 public preSaleTokenPrice = 70;
  uint256 public saleTokenPrice = 100;

  mapping (bytes32 => BuyOrder) buyOrders;

  mapping (address => uint256) lastDividend;
  mapping (uint256 =>uint256) dividendList;
  uint256 currentDividend = 0;
  uint256 dividendAmount = 0;

  struct BuyOrder {
      uint256 wether;
      address receiver;
      address payer;
      bool presale;
  }

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, bool presale);

  /**
   * event for querying Ethereum USD price for a buy order
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param amount requestid the ID of the oraclize request
   * @param amount amount of tokens purchased
   * @param presale was it bought in presale?
   */
  event PriceQuery(address indexed purchaser, address indexed beneficiary, bytes32 indexed requestid, uint256 amount, bool presale);

  /**
   * event for notifying of a Ether received to distribute as dividend
   * @param amount of dividend received
   * @param weipertoken wei received per stored token
   */
  event DividendAvalaible(uint indexed amount, uint indexed weipertoken);

  function CoinsOpenToken(address locked) {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); /* TODO: NEED TO REMOVE FOR PUBLISHING TO MAINNET */
  }

  function() payable {
    if (msg.sender == owner) {
      giveDividend();
    } else {
      buyTokens(msg.sender);
    }
  }

  /**
   * Buy tokens during the sale/presale
   * @param _receiver who should receive the tokens
   */
  function buyTokens(address _receiver) payable {
    require(validPurchase());
    bool isPresale = isInPresale();
    if (!isPresale) {
      checkPresale();
    }
    bytes32 orderId = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD).USD");
    buyOrders[orderId].wether = msg.value;
    buyOrders[orderId].receiver = _receiver;
    buyOrders[orderId].payer = msg.sender;
    buyOrders[orderId].presale = isPresale;
    PriceQuery(msg.sender, _receiver, orderId, msg.value, isPresale);
  }

  /**
   * Oraclize callback to receive Ethereum USD price
   * @param _myid ID of the request
   * @param _result String data
   */
  function __callback(bytes32 _myid, string _result) {
    require (msg.sender == oraclize_cbAddress());
    BuyOrder storage order = buyOrders[_myid];
    require (order.wether != 0);
    uint256 etherPriceUSD = parseInt(_result, 2);
    uint256 tokenPrice = saleTokenPrice;
    if (order.presale) {
      tokenPrice = preSaleTokenPrice;
    }
    uint256 centsAmount = (order.wether).div(etherPriceUSD) * 1 ether;
    uint256 tokens = centsAmount.div(tokenPrice);
    if (order.presale) {
      if (presaleSupply < tokens) {
        order.payer.transfer(order.wether);
        return;
      }
    } else {
      if (saleSupply < tokens) {
        order.payer.transfer(order.wether);
        return;
      }
    }
    checkDividend(order.receiver);
    TokenPurchase(order.payer, order.receiver, order.wether, tokens, order.presale);
    //@TODO convert amount of tokens: Have to test
    Transfer(0x0, order.receiver, tokens);
    balances[order.receiver].add(tokens);
    if (order.presale) {
      presaleSupply.sub(tokens);
    } else {
      saleSupply.sub(tokens);
    }
    buyOrders[_myid].wether = 0; //Clean the order book
  }

  function giveDividend() payable {
    require (msg.value != 0);
    dividendAmount.add(msg.value);
    dividendList[currentDividend] = msg.value / totalSupply;
    currentDividend += 1;
  }

  function checkDividend(address _account) {
    if (lastDividend[_account] != currentDividend) {
      if (balanceOf(_account) != 0) {
        uint256 toSend = 0;
        for (uint i = lastDividend[_account]; i <= currentDividend; i++) {
          toSend += balanceOf(_account).mul(dividendList[i]);
        }
        if (toSend > 0 && toSend <= dividendAmount) {
          _account.send(toSend);
          dividendAmount.sub(toSend);
        }
      }
      lastDividend[_account] = currentDividend;
    }
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    checkDividend(msg.sender);
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    checkDividend(_from);
    return super.transferFrom(_from, _to, _value);
  }

  function isInPresale() constant returns (bool) {
    return preSaleEndTime >= now;
  }

  function isInSale() constant returns (bool) {
    return saleEndTime >= now;
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = (msg.value != 0);
    return nonZeroPurchase && isInSale();
  }

  // @return true if the transaction can buy tokens
  function checkPresale() internal {
    if (!isInPresale() && presaleSupply > 0) {
      saleSupply.add(presaleSupply);
      presaleSupply = 0;
    }
  }

  /**
   * Distribute tokens from the reserve
   * @param _amount Amount to transfer
   * @param _receiver Address of the receiver
   */
  function distributeReserveSupply(uint256 _amount, address _receiver) onlyOwner {
    require (_amount <= reserveSupply);
    checkDividend(_receiver);
    balances[_receiver].add(_amount);
    reserveSupply.sub(_amount);
    Transfer(0x0, _receiver, _amount);
  }

  /**
   * Withdraw some Ether from contract
   */
  function withdraw(uint _amount) onlyOwner {
    require (_amount != 0);
    require (_amount < this.balance);
    (msg.sender).transfer(_amount);
  }

  /**
   * Withdraw Ether from contract
   */
  function withdrawEverything() onlyOwner {
    (msg.sender).transfer(this.balance);
  }

}
