pragma solidity ^0.4.24;

contract ProxyStorage {
    
    address private _owner;
    uint256 eth = 10 ** 15;
    address[] private _gods;
    mapping(address => address) _slaveToMaster;
    mapping(address => address[]) _masterToSlaves;
    address private _logicAddress;

    constructor (address logicAddress) public {
        _owner = msg.sender;
        _logicAddress = logicAddress;
    }

     modifier onlyOwner() {
        require(msg.sender == _owner, "not owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "zero address");
        _owner = newOwner;
    }

    function setLogicAddress(address _address) public onlyOwner {
        require(_address != address(0), "error : zero address");
        _logicAddress = _address;
    }

    function getLogicAddress() public view returns (address) {
        return _logicAddress;
    }

    function addSlaveToMaster(address slave, address master) public onlyOwner {
        _slaveToMaster[slave] = master;
        _masterToSlaves[master].push(slave);
    }

    function getNumGods() public view returns(uint256) {
        return _gods.length;
    }

    function addGod(address god) public onlyOwner {
        _gods.push(god);
        _slaveToMaster[god] = god; //god은 자기 자신이 god
    }

    function deleteGods() public onlyOwner {
        uint256 length = getNumGods();
        for(uint8 i=0; i<length; i++) {
            _slaveToMaster[_gods[i]] = address(0);
        }
        _gods.length = 0;
    }

    function getGods() public view returns(address[]) {
        return _gods;
    }

    function isGod(address god) public view returns(bool) {
        if(_slaveToMaster[god] == god) {
            return false;
        } else {
            return true;
        }
    }
}