const { expect } = require("chai");
const { BN, constants } = require("openzeppelin-test-helpers");

const ResourceDAO = artifacts.require("ResourceDAO");
const XS = artifacts.require("XS");

contract("summon resource dao test", function () {
    it("should deploy the XS", async function () {
        this.xs = XS.new();
    });

    it("create a named resource dao", async function () {
        this.resourceDao = ResourceDAO.new(
            "test",
            new BN("42"),
            constants.ZERO_ADDRESS
        );
        expect(this.resourceDao.address).not.eq(constants.ZERO_ADDRESS);
    });
});