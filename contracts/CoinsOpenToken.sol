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

  mapping (bytes32 => BuyOrder) buyOrders;

  struct BuyOrder {
      uint256 wei;
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
   * event for querying Ethereum EUR price for a buy order
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event PriceQuery(address indexed purchaser, address indexed beneficiary, byte32 requestid, uint256 amount, bool presale);

  function CoinsOpenToken() {

  }


  function() payable {
    if (msg.sender == owner) {

    } else {
      buyTokens(msg.sender);
    }
  }

  function buyTokens(address _receiver) payable {
    require(validPurchase());
    bool isPresale = preSaleEndTime >= now;
    byte32 orderId = oraclize_query("URL", "json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=EUR).EUR");
    buyOrders[orderId].wei = msg.value;
    buyOrders[orderId].receiver = _receiver;
    buyOrders[orderId].payer = msg.sender;
    buyOrders[orderId].presale = isPresale;
    PriceQuery(msg.sender, _receiver, orderId, msg.value, isPresale);
  }

  /**
   * Oraclize callback to receive Ethereum EUR price
   * @param _myid ID of the request
   * @param _result String data
   */
  function __callback(bytes32 _myid, string _result) {
    require (msg.sender == oraclize_cbAddress());
    BuyOrder order = buyOrders[_myid];
    require (order != 0);
    uint etherPriceEUR = parseInt(_result, 2);
    // Logic for buying and sending token here
    //@TODO check preSaleEndTime
    //@TODO check number of token already distributes
    //@TODO convert amount of tokens
    //@TODO transfer the tokens
  }


  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase;
  }

}
