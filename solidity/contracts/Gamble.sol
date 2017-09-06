pragma solidity ^0.4.11;

import './Owned.sol';
import './ERC20Token.sol';


contract Gamble is Owned, ERC20Token{
    struct Gambler{
    uint256 bet;
    uint256 bounty;
    uint256 dice;
    uint256 hash;
    }

    uint256 public DEFAULT_SEAT = 3;
    uint256 public MIN_SEAT = 3;
    uint256 public MAX_SEAT = 10;
    uint256 public MAX_DICE = 1000;
    uint256 public JETTON = 1 finney;
    uint256 public OWNER_BET = 10;

    uint256 public seat = DEFAULT_SEAT;
    uint256 public gamblerNum = 0;
    uint256 public maxJetton = 0;
    uint256 public bountyPool = 0;
    uint256 public balance = 0;
    uint256 public round = 0;
    address public banker = 0x0;
    mapping (uint256 => mapping (address => Gambler)) public rounds;
    mapping (uint256 => address[]) public gamblers;


    function Gamble(string _name, string _symbol, uint8 _decimals) payable
    ERC20Token(_name, _symbol, _decimals){
        deposit();
        if(balance >= OWNER_BET && OWNER_BET > 0){
            balance = safeSub(balance, OWNER_BET);
            setBet(this, OWNER_BET);
        }
    }

    modifier validAmount(uint256 _amount){
        require(_amount > 0);
        _;
    }

    modifier bankerOnly(){
        require(msg.sender == banker);
        _;
    }

    modifier validSeat(uint256 _seat){
        require(_seat >= MIN_SEAT);
        require(_seat <= MAX_SEAT);
        require(_seat >= safeAdd(gamblerNum, 1));
        _;
    }

    function etherToJetton(uint256 _ether) internal returns(uint256 jetton){
        return safeDiv(_ether, JETTON);
    }

    function jettonToEther(uint256 _jetton) internal returns(uint256 _ether){
        return safeMul(_jetton, JETTON);
    }

    function setBet(address _gambler, uint256 _jetton) internal{
        balanceOf[_gambler] = safeSub(balanceOf[_gambler], _jetton);
        balanceOf[this] = safeAdd(balanceOf[this], _jetton);

        Transfer(_gambler, this, _jetton);

        if(rounds[round][_gambler].bet == 0){
            gamblerNum = safeAdd(gamblerNum, 1);
            gamblers[round].push(_gambler);
        }
        rounds[round][_gambler].bet = safeAdd(rounds[round][_gambler].bet, _jetton);
        bountyPool = safeAdd(bountyPool, _jetton);
        if(_jetton > maxJetton){
            banker = _gambler;
            maxJetton = _jetton;
        }

        setHash(_gambler);

        if(gamblerNum == seat){
            distributeBounty();
            initRound();
        }
    }

    function setHash(address _gambler) internal{
        uint256 hashVal = uint256(block.blockhash(block.number - 1));
        uint256 blockNumber = uint256(sha3(uint256(sha3(hashVal, _gambler)), now)) % block.number;
        hashVal = uint256(block.blockhash(blockNumber));
        rounds[round][_gambler].hash = uint256(sha3(uint256(sha3(hashVal, _gambler)), now));
    }

    function distributeBounty() internal{
        uint256 totalDice = 0;
        for(uint256 i = 0; i < gamblerNum; i++){
            rounds[round][gamblers[round][i]].dice = uint256(sha3(rounds[round][gamblers[round][i]].hash, rounds[round][gamblers[round][gamblerNum - 1]].hash)) % MAX_DICE;
            totalDice = safeAdd(totalDice, safeMul(rounds[round][gamblers[round][i]].bet, rounds[round][gamblers[round][i]].dice));
        }
        for(uint256 j = 0; j < gamblerNum; j++){
            rounds[round][gamblers[round][j]].bounty = safeDiv(safeMul(safeMul(rounds[round][gamblers[round][j]].bet, rounds[round][gamblers[round][j]].dice), bountyPool), totalDice);
        }
        for(uint256 k = 0; k < gamblerNum; k++){
            bountyPool = safeSub(bountyPool, rounds[round][gamblers[round][k]].bounty);
            balanceOf[this] = safeSub(balanceOf[this], rounds[round][gamblers[round][k]].bounty);
            balanceOf[gamblers[round][k]] = safeAdd(balanceOf[gamblers[round][k]], rounds[round][gamblers[round][k]].bounty);

            if(gamblers[round][k] == address(this)){
                balance = safeAdd(balance, rounds[round][gamblers[round][k]].bounty);
            }

            Transfer(this, gamblers[round][k], rounds[round][gamblers[round][k]].bounty);
        }
    }

    function initRound() internal{
        round = safeAdd(round, 1);
        banker = 0x0;
        gamblerNum = 0;
        maxJetton = 0;
        balance = safeAdd(balance, bountyPool);
        bountyPool = 0;
        if(balance >= OWNER_BET && OWNER_BET > 0){
            balance = safeSub(balance, OWNER_BET);
            setBet(this, OWNER_BET);
        }
    }

    function deposit() public payable
    validAmount(msg.value) returns(uint256 jetton){
        require(msg.value >= JETTON);
        jetton = etherToJetton(msg.value);
        if(safeSub(msg.value, jettonToEther(jetton)) != 0)
        msg.sender.transfer(safeSub(msg.value, jettonToEther(jetton)));
        if(msg.sender != owner){
            balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], jetton);
            totalSupply = safeAdd(totalSupply, jetton);
            Transfer(0x0, msg.sender, jetton);
        } else{
            balance = safeAdd(balance, jetton);
            balanceOf[this] = safeAdd(balanceOf[this], jetton);
            totalSupply = safeAdd(totalSupply, jetton);
            Transfer(0x0, this, jetton);
        }
        return jetton;
    }

    function withdraw(uint256 _jetton) public
    validAmount(_jetton){
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _jetton);
        totalSupply = safeSub(totalSupply, _jetton);
        Transfer(msg.sender, 0x0, _jetton);

        msg.sender.transfer(jettonToEther(_jetton));
    }

    function bet(uint256 _jetton) public
    validAmount(_jetton){
        setBet(msg.sender, _jetton);
    }

    function setSeat(uint256 _seat) public bankerOnly validSeat(_seat){
        seat = _seat;
    }

    function setMinSeat(uint256 _seat) public ownerOnly{
        require(_seat >= 2);
        require(_seat <= MAX_SEAT);
        MIN_SEAT = _seat;
        DEFAULT_SEAT = MIN_SEAT;
    }

    function setMaxSeat(uint256 _seat) public ownerOnly{
        require(_seat >= MIN_SEAT);
        MAX_SEAT = _seat;
    }

    function setOwnerBet(uint256 _jetton) public ownerOnly{
        require(_jetton >= 0);
        OWNER_BET = _jetton;
    }

    function collectBalance() public ownerOnly{
        require(balance > 0);
        uint256 _balance = balance;
        balance = 0;

        balanceOf[this] = safeSub(balanceOf[this], _balance);
        totalSupply = safeSub(totalSupply, _balance);
        Transfer(this, 0x0, _balance);

        owner.transfer(jettonToEther(_balance));
    }

    function() payable{
        uint256 jetton = deposit();
        if(msg.sender != owner)
            bet(jetton);
    }

}
