pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2; 

contract RecipeTree {

    struct RecipeNode {
        uint256 id;

        string name;
        address ownerDAO;
        bool isBase;
        uint16 timesRequested;

        uint32 truePrice;

        bytes32 parent;
        bytes32[] nodes;
    }

    mapping(uint256 => bytes32) private nodeIDs;
    mapping(bytes32 => RecipeNode) private nodes;

    uint256 private nodeCounter = 1;

    function addTop(
        string calldata _name,
        address _ownerDAO,
        bool _isBase,
        bytes32[] _components 
    )
        external
    {
        
    }

    function add(
        string calldata _name,
        address _ownerDAO,
        bool _isBase,
        bytes32 _parent
    )
        external
    {
        require(_name.length > 0, "RecipeTree::name must not be empty");

        bytes32 path = keccak256(_parent, _name);
        RecipeNode storage node = nodes[path];
        require(0x0 == node.path, "RecipeTree::path exists");

        nodes[path] = RecipeNode({
            name: _name,
            ownerDAO: _ownerDAO,
            isBase: _isBase,
            nodes: new bytes32[](0)
        });
        nodes[_parent].nodes.push(path);
        nodeIDs[nodeCounter] = path;
        nodeCounter++;
    }

    function getByID(uint256 _id) 
        external 
        view
        returns (RecipeNode memory)
    {
        return nodes[nodeIDs[_id]];
    }

    function getByName(
        string calldata _name,
        bytes32 _parent
    )
        external
        view
        returns (RecipeNode memory)
    {
        return nodes[keccak256(_parent, _name)];
    }

    function cnt() 
        external
        view
        returns (uint256)
    {
        return nodeCounter-1;
    }

}