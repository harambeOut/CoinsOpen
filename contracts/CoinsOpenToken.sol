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
  uint public totalSupply = 210000000000000000 ;

  uint256 public saleStartTime = 0;
  uint256 public saleEndTime = 0;
  uint256 public preSaleEndTime = 0;

  uint256 public preSaleTokenPrice = 70;
  uint256 public saleTokenPrice = 100;


  mapping (bytes32 => BuyOrder) buyOrders;

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

  function CoinsOpenToken(address locked) {
    OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
  }

  function() payable {
    if (msg.sender == owner) {

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
    TokenPurchase(order.payer, order.receiver, order.wether, tokens, order.presale);
    // Logic for buying and sending token here
    //@TODO check number of token already distributes
    //@TODO convert amount of tokens: Have to test
    //@TODO transfer the tokens
    buyOrders[_myid].wether = 0; //Clean the order book
  }

  function isInPresale() constant returns (bool) {
    return preSaleEndTime >= now;
  }


  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = (msg.value != 0);
    return nonZeroPurchase;
  }

  function withdraw() onlyOwner {
    (msg.sender).transfer(this.balance);
  }

}
