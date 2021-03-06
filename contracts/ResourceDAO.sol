pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import "./moloch/Moloch.sol";
import "./MultiResourceToken.sol";

contract ResourceDAO
{
    enum Status {
        Requested,
        Claimed,
        Completed
    }

    struct Component {
        address adr; // Which is the address of the ResourceDAO.
        uint256 recipeID; // Which recipe ID in the resource DAO.
        uint256 amount; // How much of the resource.
    }

    struct Recipe {
        string name;
        Component[] components;
        uint256 truePrice;
        uint256 timesrequested; // this increments every request to compute the percentage of orders w.r.t. the rest;
        //string IPFSInfo;//Resource description and parameters following DAO-wide standard decided by prosumers
    }

    struct Request {
        address requester;
        uint256 recipeID;
        uint256[] trueprice;
        uint256 amounts;
        string location; //(geohash)
        uint8 status;
        uint256 creation;
        //string IPFSInfo;
    }

    Moloch dao;

    MultiResourceToken token;

    // Balance of resource.
    mapping (address=>int256) private balanceOf;

    // Each dao contains information about its recipes
    Recipe[] public recipes;

    uint256 public nRecipes;
    uint256 public bestrecipe; // Selected by DAO prosumer signaling

    Request[] public requests;

    string public label; // The name of this resource
    uint256 public id; // unique identifier of the resource
    uint256 public nrequests; // Current overall demand of resource

    event NewRequest(string label, uint256 recipeID, uint256 amount);
    event NewRecipe(string label);

    constructor(
        address _multiToken,
        string memory _label,
        uint _id
    ) 
        public
    {
        require(address(0) != _multiToken);
        require(address(0) != _truePriceRegistry);

        token = MultiResourceToken(_multiToken);

        dao = Moloch(msg.sender);

        nrequests = 0;
        nRecipes = 0;
        bestrecipe = 0;
        label = _label;
        id = _id;
    }

    // The request function is called to make an order.
    // Assets used by the request should enter escrow agreement
    // The order is forwarded to all sub-resources,
    // The bestrecipe should be decided using token-curated registries
    //
    function request(uint _amount, string memory _location) public
    {
        requestRecipe(bestrecipe, _amount, _location);
    }

    // The
    // call for specific recipe
    function requestRecipe(
        uint256 _recipeID,
        uint256 _amount, 
        string memory _location
    ) 
        public
    {   
        uint256[] memory trueprice = getRecipeTruePrice(_recipeID);
        Request memory order = Request (msg.sender, _recipeID,  trueprice, _amount, _location, 0 , now);
        nrequests += _amount;
        requests.push(order);

        if (nRecipes == 0 || _recipeID >= nRecipes ) return ; //Check validity of request

        //Order component resources
        for (uint i = 0; i<recipes[_recipeID].components.length; i++)
        {
            //if (recipes[_recipeID].components[i] == address(0x0)) return; //exit if no additional components are required

            uint ramount =  recipes[_recipeID].amounts[i] * _amount; //Here we are multipling needed components with the requested amount
            uint rrecipe = recipes[_recipeID].componentRecipe[i];

            ResourceDAO r = ResourceDAO(recipes[_recipeID].components[i]);
            r.requestRecipe(rrecipe, ramount,_location);
        }

        //Notify listeners
        emit NewRequest(label,_recipeID,_amount);
    }

    function getRequestInfo(uint requestId ) public view returns (
      address requester,
      uint amounts,
      string memory location,
      uint status,
      uint creation
    ){
        
      Request storage order =  requests[ requestId ];
      requester = order.requester;
      amounts = order.amounts;
      location = order.location;
      status = order.status;
      creation = order.creation;

    }

    function getStatus(uint requestId) public view returns (uint status) {
      Request memory order = requests[requestId];
      status = order.status;
      return status;
    }

    //concludes delivery of the product or service.
    //Value should move from the user account to the entire value chain
    //Also reputation should be minted in all parties involved
    function confirm(uint requestId) public
    {
        Request storage order = requests[requestId];
        order.status = 2;
        //Transfer agreed amount from requester to supplier

        exchange.addAssets(msg.sender,order.trueprice, order.amounts);
        exchange.subtractAssets(order.requester,order.trueprice, order.amounts);
        //exchange.wallets[order.requester][id] -= order.amounts;
        //exchange.wallets[msg.sender][id] += order.amounts;

    }

    function getRecipes() view public returns (string[] memory) {
        string[] memory res = new string[](nRecipes);

        for (uint i = 0; i < nRecipes; i++) {
            res[i] = recipes[i].name;
        }

        return res;
    }

    // function getTruePrice(uint recipeID) view public returns (uint) {
    //     uint sum = 0;
    //     if ( nRecipes == 0 ) return 1; // exit rule, change for different assets;
    //     for (uint i = 0; i < recipes[recipeID].components.length; i++){
    //         sum+=recipes[recipeID].amounts[i]*ResourceDAO(recipes[recipeID].components[i]).getTruePrice(recipes[recipeID].componentRecipe[i]);
    //     }
    //     return sum;
    // }

    // function getTruePrice(uint recipeID) view public returns (uint[] memory) {
    //    uint[] memory result = new uint[](exchange.nresources()+1); // resource 0 is deiscarded
    //    if ( nRecipes == 0 )  {
    //        result[id]++;
    //        return result; // exit recursion on basic resources;
    //    }
    //     for (uint i = 0; i < recipes[recipeID].components.length; i++){
    //         ResourceDAO r = ResourceDAO(recipes[recipeID].components[i]);
    //         result = mulVectors(addVectors(result, r.getTruePrice(recipes[recipeID].componentRecipe[i])),recipes[recipeID].amounts[i]);
    //     }
    //     return result;
    // }


     function  addVectors (uint[] memory lhs, uint[] memory rhs) pure public returns (uint[] memory)
    {
        uint[] memory v =  new uint[](lhs.length);
        for (uint i = 0; i < lhs.length; i++)
            v[i] = lhs[i] + rhs[i];
        return v;
    }

    function  mulVectors (uint[] memory lhs, uint scalar) pure  public returns (uint[] memory)
    {
        uint[] memory v = new uint[](lhs.length);
        for (uint i = 0; i < lhs.length; i++)
            v[i] = lhs[i] * scalar;
        return v;
    }

    function addRecipe(
        string memory _name,
        Component[] memory _components
    )
        public 
    {
        uint256 tPrice = 0;
        for (uint256 i = 0; i < _components.length; i++) {
            ResourceDAO r = ResourceDAO(recipes[_recipeID].components[i]);
            tPrice = tPrice + r.getRecipeTruePrice(_recipeID);
        }
        recipes.push(Recipe(_name, _components, tPrice, 0));
        nRecipes++;
        
        emit NewRecipe(_name);
    }

   function getComponents(uint _recipeID) view public returns (address[] memory ){
        return recipes[_recipeID].components;
    }

    function getRecipeTruePrice(uint256 _recipeID) public view returns(uint256) {
        return recipes[_recipeID].truePrice;
    }


    //This function is called by the people contributing. They will ask for a debt from all the sub-resources i
    //It mints one unfungible tokens where the contributions are recorded
    // function make(uint recipeID){
    //     //require good standing of sender ( positive reputation, no debts, track record, escrow)
    //     //
    //     msg.sender.transfer(recipeID.componentID)
    //     //mint output token
    // }
}
