pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import "./ResourceDAO.sol";

contract XS {

    mapping (string => uint) public toId;
    mapping (uint => address) public toAddress;

    uint public nresources;

    event NewResource(string _label);

    constructor() public {
      nresources = 0;
    }

    // check if resource exists. If so, send order to resource, otherwise it should first create the resource and then send an order to it.
    function request(string memory label,uint recipe, string memory location, uint amount) public returns (bool success)
    {
        //bytes32 label = sha3(_label);
        uint id = toId[label];
        if (id > 0x0)//NOTE: id 0 reserved for any unmatched resource
        {
           ResourceDAO res = ResourceDAO(toAddress[id]);
        }
        else //if resourece does not exist, create one, then request it
        {
            ResourceDAO res =  ResourceDAO(createResource(label));
        }
        res.requestRecipe(recipe, amount, location);
        return true;
    }
    
    function subtractAssets(address _address, uint[] memory assets, uint amount) public {
        //TODO:check for permission
        for (uint i = 0; i<  assets.length; i++){
           wallets[_address][i] -= int(assets[i] * amount);
        }
        
    }
    
      function addAssets(address _address, uint[] memory assets, uint amount) public {
        //TODO:check for permission
        for (uint i = 0; i<  assets.length; i++){
           wallets[_address][i] += int(assets[i] * amount);
        }
        
    }

    function createResource(string memory label) public returns (address){
        nresources += 1; // Resource index starts from 1.
        ResourceDAO newres = new ResourceDAO(label, nresources, address(this));
        toAddress[nresources] = address(newres);
        toId[label] = nresources;
  
        emit NewResource(label);
        return address(newres);
    }


    function listResources() public view returns ( int [] memory )
    {
      int[] memory ret= new int[](uint (nresources));
      for(uint i=0; i < uint(nresources); i++)
        {
            ResourceDAO res = ResourceDAO(toAddress[i+1]);

            ret[i]= int(res.nrequests());
        }
        return ret;
    }

    function listResourcesName() public view returns ( string [] memory)
    {
      string[] memory ret =new string[](uint (nresources));
      for(uint i=0; i < uint(nresources); i++)
        {
            ResourceDAO res = ResourceDAO(toAddress[i+1]);

            ret[i]= string(res.label());
        }
        return ret;
    }
}
