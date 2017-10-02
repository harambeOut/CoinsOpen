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

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function CoinsOpenToken() {

  }


  function() payable {
    if (msg.sender == owner) {

    } else {
      buyTokens(msg.sender);
    }
  }

  function buyTokens(address _receiver) {
    require(validPurchase());

  }

  function __callback(bytes32 myid, string result) {
    require (msg.sender == oraclize_cbAddress());

  }


  // @return true if the transaction can buy tokens
  function validPurchase() internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    return nonZeroPurchase;
  }



}
