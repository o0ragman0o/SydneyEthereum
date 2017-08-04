/*
file:   SydneyEthereum.sol
ver:    0.1.0
updated:4-Aug-2017
author: Darryl Morris
email:  o0ragman0o AT gmail.com

An ERC20 compliant token with reentry protection and safe math.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes
-------------
0.1.0
*/

pragma solidity ^0.4.13;

// ERC20 Standard Token Interface with safe token limit and reentry protection
contract ERC20Interface
{
/* Events */
    // Triggered when tokens are transferred.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value);

/* Modifiers */

/* Function Abstracts */

    /// @return The total supply of tokens
    function totalSupply() public constant returns (uint);
    
    /// @return The trading symbol;
    function symbol() public constant returns (string);

    /// @param _addr The address of a token holder
    /// @return The amount of tokens held by `_addr`
    function balanceOf(address _addr) public constant returns (uint);

    /// @param _owner The address of a token holder
    /// @param _spender the address of a third-party
    /// @return The amount of tokens the `_spender` is allowed to transfer
    function allowance(address _owner, address _spender) public constant
        returns (uint);

    /// @notice Send `_amount` of tokens from `msg.sender` to `_to`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to transfer
    function transfer(address _to, uint256 _amount) public returns (bool);

    /// @notice Send `_amount` of tokens from `_from` to `_to` on the condition
    /// it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to transfer
    function transferFrom(address _from, address _to, uint256 _amount)
        public returns (bool);

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    /// its behalf
    /// @param _spender The address of the approved spender
    /// @param _amount The amount of tokens to transfer
    function approve(address _spender, uint256 _amount) public returns (bool);
}

contract ERC20Token is ERC20Interface
{

/* Constants */
    bytes32 constant public VERSION = "ERC20 0.4.6-o0ragman0o";

/* State */
    // The Total supply of tokens
    uint totSupply;
    
    /// @return Token symbol
    string sym;
    
    // Token ownership mapping
    mapping (address => uint) balance;
    
    // Allowances mapping
    mapping (address => mapping (address => uint)) allowed;

/* Funtions Public */

    function symbol()
        public
        constant
        returns (string)
    {
        return sym;
    }
    
    // Using an explicit getter allows for function overloading    
    function totalSupply()
        public
        constant
        returns (uint)
    {
        return totSupply;
    }
    
    // Using an explicit getter allows for function overloading    
    function balanceOf(address _addr)
        public
        constant
        returns (uint)
    {
        return balance[_addr];
    }
    
    // Using an explicit getter allows for function overloading    
    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint remaining_)
    {
        return allowed[_owner][_spender];
    }
        

    // Send _value amount of tokens to address _to
    // Reentry protection prevents attacks upon the state
    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        return xfer(msg.sender, _to, _value);
    }

    // Send _value amount of tokens from address _from to address _to
    // Reentry protection prevents attacks upon the state
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return xfer(_from, _to, _value);
    }

    // Process a transfer internally.
    function xfer(address _from, address _to, uint _value)
        internal
        returns (bool)
    {
        require(_value <= balance[_from]);
        balance[_from] -= _value;
        balance[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    // Approves a third-party spender
    // Reentry protection prevents attacks upon the state
    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}

contract SydneyEthereum is ERC20Token
{
    address owner = msg.sender;
    
    mapping (uint => uint) ballots;
    mapping (uint => mapping(address => uint)) voters;
    
    function SydneyEthereum()
    {
        sym = "SYD";
    }
    
    function issue(address _addr, uint _amount)
        public
        returns (bool)
    {
        require(owner == msg.sender);
        totSupply += _amount;
        balance[_addr] += _amount;
        Transfer(0x0, _addr, _amount);
        return true;
    }
    
    function redeem( address _addr, uint _amount)
        public
        returns (bool)
    {
        require(owner == msg.sender);
        require(balance[_addr] >= _amount);
        totSupply -= _amount;
        balance[_addr] -= _amount;
        Transfer(_addr, 0x0, _amount);
        return true;
    }
    
    // Clears existing vote and registers vote tokens against ballot if yea
    function vote(uint _ballotId, bool _yea)
        public
        returns (bool)
    {
        ballots[_ballotId] -= voters[_ballotId][msg.sender];
        delete voters[_ballotId][msg.sender];
        
        if (_yea) {
            ballots[_ballotId] += balance[msg.sender];
            voters[_ballotId][msg.sender] = balance[msg.sender];
        }
        return true;
    }
}