pragma solidity ^0.5.10;

contract MultiResourceToken {

    /////
    // Storage:
    /////

    // Owner => Resource => Balance
    mapping(address => mapping(uint256 => int256)) private resourceBalance;

    /////
    // Functions:
    /////

    function add(
        address _src,
        uint256 _tag,
        uint256 _amt
    ) external {
        require(address(0) != _src, "MultiResourceToken::_src must not be zero");

        // TODO@pax: safe math here!
        resourceBalance[_src][_tag] += _amt;
    }

    function sub(
        address _src,
        uint256 _tag,
        uint256 _amt
    ) external {
        require(address(0) != _src, "MultiResourceToken::_src must not be zero");

        // TODO@pax: safe math here!
        resourceBalance[_src][_tag] -= _amt;
    }

}
