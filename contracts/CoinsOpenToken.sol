pragma solidity ^0.4.8;

import "./StandardToken.sol";

contract CoinsOpenToken is StandardToken
{

  // Token informations
  string public constant name = "COT";
  string public constant symbol = "COT";
  uint8 public constant decimals = 18;

  uint public totalSupply = 23000000000000000000000000;
  uint256 public presaleSupply = 2000000000000000000000000;
  uint256 public saleSupply = 13000000000000000000000000;
  uint256 public reserveSupply = 8000000000000000000000000;

  uint256 public saleStartTime = 1511136000; /* Monday, November 20, 2017 12:00:00 AM */
  uint256 public saleEndTime = 1513728000; /* Wednesday, December 20, 2017 12:00:00 AM */
  uint256 public preSaleStartTime = 1508457600; /* Friday, October 20, 2017 12:00:00 AM */
  uint256 public developerLock = 1500508800;

  uint256 public totalWeiRaised = 0;

  uint256 public preSaleTokenPrice = 20;
  uint256 public saleTokenPrice = 40;

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
   * event for notifying of a Ether received to distribute as dividend
   * @param amount of dividend received
   */
  event DividendAvailable(uint amount);

  /**
   * event triggered when sending dividend to owner
   * @param receiver who is receiving the payout
   * @param amountofether paid received
   */
  event SendDividend(address indexed receiver, uint amountofether);

  function CoinsOpenToken() {
    assert(totalSupply == presaleSupply + saleSupply + reserveSupply);
    //OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); /* TODO: NEED TO REMOVE FOR PUBLISHING TO MAINNET */
  }

  function() payable whenNotPaused {
    if (msg.sender == owner) {
      giveDividend();
    } else {
      buyTokens(msg.sender);
    }
  }

  function endSale() whenNotPaused {
    require (!isInSale());
    require (saleSupply != 0);
    reserveSupply = reserveSupply.add(saleSupply);
  }

  /**
   * Buy tokens during the sale/presale
   * @param _receiver who should receive the tokens
   */
  function buyTokens(address _receiver) payable whenNotPaused {
    require (msg.value != 0);
    require (_receiver != 0x0);
    require (isInSale());
    bool isPresale = isInPresale();
    if (!isPresale) {
      checkPresale();
    }
    uint256 tokenPrice = saleTokenPrice;
    if (isPresale) {
      tokenPrice = preSaleTokenPrice;
    }
    uint256 tokens = (msg.value).mul(tokenPrice) / 100;
    if (isPresale) {
      if (presaleSupply < tokens) {
        msg.sender.transfer(msg.value);
        return;
      }
    } else {
      if (saleSupply < tokens) {
        msg.sender.transfer(msg.value);
        return;
      }
    }
    checkDividend(_receiver);
    TokenPurchase(msg.sender, _receiver, msg.value, tokens, isPresale);
    totalWeiRaised = totalWeiRaised.add(msg.value);
    Transfer(0x0, _receiver, tokens);
    balances[_receiver] = balances[_receiver].add(tokens);
    if (isPresale) {
      presaleSupply = presaleSupply.sub(tokens);
    } else {
      saleSupply = saleSupply.sub(tokens);
    }
  }

  /**
   * @dev Pay this function to add the dividends
   */
  function giveDividend() payable whenNotPaused {
    require (msg.value != 0);
    dividendAmount = dividendAmount.add(msg.value);
    dividendList[currentDividend] = (msg.value).mul(10000000000).div(totalSupply);
    currentDividend = currentDividend.add(1);
    DividendAvailable(msg.value);
  }

  /**
   * @dev Returns true if we are still in pre sale period
   * @param _account The address to check and send dividends
   */
  function checkDividend(address _account) whenNotPaused {
    if (lastDividend[_account] != currentDividend) {
      if (balanceOf(_account) != 0) {
        uint256 toSend = 0;
        for (uint i = lastDividend[_account]; i < currentDividend; i++) {
          toSend += balanceOf(_account).mul(dividendList[i]).div(10000000000);
        }
        if (toSend > 0 && toSend <= dividendAmount) {
          _account.transfer(toSend);
          dividendAmount = dividendAmount.sub(toSend);
          SendDividend(_account, toSend);
        }
      }
      lastDividend[_account] = currentDividend;
    }
  }

  /**
  * @dev transfer token for a specified address checking if they are dividends to pay
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    checkDividend(msg.sender);
    return super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another checking if they are dividends to pay
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    checkDividend(_from);
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Returns true if we are still in pre sale period
   */
  function isInPresale() constant returns (bool) {
    return saleStartTime > now;
  }

  /**
   * @dev Returns true if we are still in sale period
   */
  function isInSale() constant returns (bool) {
    return saleEndTime >= now && preSaleStartTime <= now;
  }

  // @return true if the transaction can buy tokens
  function checkPresale() internal {
    if (!isInPresale() && presaleSupply > 0) {
      saleSupply = saleSupply.add(presaleSupply);
      presaleSupply = 0;
    }
  }

  /**
   * Distribute tokens from the reserve
   * @param _amount Amount to transfer
   * @param _receiver Address of the receiver
   */
  function distributeReserveSupply(uint256 _amount, address _receiver) onlyOwner whenNotPaused {
    require (_amount <= reserveSupply);
    require (now >= developerLock);
    checkDividend(_receiver);
    balances[_receiver] = balances[_receiver].add(_amount);
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
