// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {AdminFacet} from "../src/AdminFacet.sol";
import {MintFacet} from "../src/MintFacet.sol";
import {IDiamondCut} from "../lib/diamond-3-hardhat/contracts/interfaces/IDiamondCut.sol";
import {Diamond} from "../lib/diamond-3-hardhat/contracts/Diamond.sol";
import {DiamondCutFacet} from "../lib/diamond-3-hardhat/contracts/facets/DiamondCutFacet.sol";
import {ERC721MetadataStorage} from "@solidstate-network/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

import {DeployDiamondScript} from "../script/DeployDiamond.s.sol";

import {console} from "../lib/forge-std/src/console.sol";

contract AdminFacetTest is Test {
    Diamond public diamond;
    DiamondCutFacet public diamondCutFacetInstance;
    AdminFacet public adminFacetAsDiamond; // Прокси, обернутый в ABI фасета
    MintFacet public mintFacetAsDiamond;
    AdminFacet public adminFacetInstance;  // Сам развернутый контракт фасета
    MintFacet public mintFacetInstance;

    address public owner = address(1);
    address public alien = address(2);
    address public newAdmin = address(3);
    address public nftReceiver  = address(4);

    function setUp() public {
        DeployDiamondScript deployer = new DeployDiamondScript();
        DeployDiamondScript.DeploymentResult memory result = deployer.run(owner);

        adminFacetAsDiamond = AdminFacet(result.diamondAddress);
        mintFacetAsDiamond = MintFacet(result.diamondAddress);
    }

    /*  Tests for addAdmin function */
    function test_addAdmin_ShouldRevert_WhenNotOwner() public {
        vm.startPrank(alien);

        vm.expectRevert("LibDiamond: Must be contract owner");
        adminFacetAsDiamond.addAdmin(newAdmin);

        vm.stopPrank();
    }
    function test_addAdmin_ShouldRevert_WhenZeroAddress() public {
        vm.startPrank(owner);

        vm.expectRevert("Admin cannot be zero address");
        adminFacetAsDiamond.addAdmin(address(0));

        vm.stopPrank();
    }
    function test_addAdmin_ShouldRevert_WhenAlreadyAdmin() public {
        vm.startPrank(owner);
        adminFacetAsDiamond.addAdmin(newAdmin);

        vm.expectRevert("Address is already admin");
        adminFacetAsDiamond.addAdmin(newAdmin);

        vm.stopPrank();
    }
    function test_addAdmin_Success() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, false);
        emit AdminFacet.AdminAdded(newAdmin);

        adminFacetAsDiamond.addAdmin(newAdmin);
        vm.stopPrank();

        assertTrue(adminFacetAsDiamond.isAdmin(newAdmin));
    }

    /*  Tests for removeAdmin function */
    function test_removeAdmin_ShouldRevert_WhenNotOwner() public {
        vm.startPrank(alien);

        vm.expectRevert("LibDiamond: Must be contract owner");
        adminFacetAsDiamond.removeAdmin(newAdmin);

        vm.stopPrank();
    }
    function test_removeAdmin_ShouldRevert_WhenZeroAddress() public {
        vm.startPrank(owner);

        vm.expectRevert("Admin cannot be zero address");
        adminFacetAsDiamond.removeAdmin(address(0));

        vm.stopPrank();
    }
    function test_removeAdmin_ShouldRevert_WhenNotAdmin() public {
        vm.startPrank(owner);

        vm.expectRevert("Address is not an admin");
        adminFacetAsDiamond.removeAdmin(newAdmin);

        vm.stopPrank();
    }
    function test_removeAdmin_ShouldRevert_WhenAlreadyRemoved() public {
        vm.startPrank(owner);
        adminFacetAsDiamond.addAdmin(newAdmin);
        adminFacetAsDiamond.removeAdmin(newAdmin);

        vm.expectRevert("Address is not an admin");
        adminFacetAsDiamond.removeAdmin(newAdmin);

        vm.stopPrank();
    }
    function test_removeAdmin_Success() public {
        vm.startPrank(owner);
        adminFacetAsDiamond.addAdmin(newAdmin);

        vm.expectEmit(true, false, false, false);
        emit AdminFacet.AdminRemoved(newAdmin);

        adminFacetAsDiamond.removeAdmin(newAdmin);
        vm.stopPrank();

        assertFalse(adminFacetAsDiamond.isAdmin(newAdmin));
    }

    /*  Tests for isAdmin function */
    function test_isAdmin_ShouldNorRevert_WhenCallerNotOwner() public {
        vm.prank(alien);

        try adminFacetAsDiamond.isAdmin(newAdmin) returns (bool result) {
            assertFalse(result);
        } catch {
            fail("The call reverted, but it should NOT have reverted");
        }
    }
    function test_isAdmin_ShouldNorRevert_WhenCallerNotAdmin() public {
        vm.prank(alien);

        try adminFacetAsDiamond.isAdmin(newAdmin) returns (bool result) {
            assertFalse(result);
        } catch {
            fail("The call reverted, but it should NOT have reverted");
        }
    }
    function test_isAdmin_ShouldNorRevert_WhenCallerAdmin() public {
        vm.prank(owner);
        adminFacetAsDiamond.addAdmin(newAdmin);
        vm.stopPrank();

        vm.prank(newAdmin);

        try adminFacetAsDiamond.isAdmin(newAdmin) returns (bool result) {
            assertTrue(result);
        } catch {
            fail("The call reverted, but it should NOT have reverted");
        }
    }
    function test_isAdmin_ShouldRevertTrue_WhenUserIsAdmin() public {
        vm.prank(owner);
        adminFacetAsDiamond.addAdmin(newAdmin);

        assertTrue(adminFacetAsDiamond.isAdmin(newAdmin));

        vm.stopPrank();
    }
    function test_isAdmin_ShouldRevertFalse_WhenUserNotAdmin() public {
        vm.startPrank(alien);

        assertFalse(adminFacetAsDiamond.isAdmin(newAdmin));

        vm.stopPrank();
    }

    /*  Tests for setBaseURI function */
    function test_setBaseURI_ShouldRevert_WhenNotOwner() public {
        vm.startPrank(alien);

        vm.expectRevert("LibDiamond: Must be contract owner");
        adminFacetAsDiamond.setBaseURI("https://mygame.com");

        vm.stopPrank();
    }
    function test_setBaseURI_ShouldReturnBaseUri() public {
        uint256 nftId = mintFacetAsDiamond.mint();
        string memory initUriFromScript = "https://test.com";
        string memory resultNftUri = string.concat(initUriFromScript, "_", vm.toString(nftId));

        string memory baseTokenUri = mintFacetAsDiamond.tokenURI(nftId);

        assertEq(baseTokenUri, resultNftUri);
    }
    function test_setBaseURI_ShouldReturnUpdateBaseUri() public {
        uint256 nftId = mintFacetAsDiamond.mint();

        vm.prank(owner);
        adminFacetAsDiamond.setBaseURI("https://mygame.com");

        string memory actualTokenUri = mintFacetAsDiamond.tokenURI(nftId);
        assertEq(actualTokenUri, string.concat("https://mygame.com", "_", vm.toString(nftId)));
    }

    /*  Tests for setCustomNftURIByAdmin function */
    function test_setCustomNftURIByAdmin_ShouldRevert_WhenNftNotExist() public {
        vm.startPrank(alien);

        vm.expectRevert("ERC721: token does not exist");
        adminFacetAsDiamond.setCustomNftURIByAdmin(1,"https://mygame.com");

        vm.stopPrank();
    }
    function test_setCustomNftURIByAdmin_ShouldRevert_WhenNotAdmin() public {
        vm.startPrank(alien);
        uint256 omnichainId = mintFacetAsDiamond.mint();

        vm.expectRevert("Caller is not Admin");
        adminFacetAsDiamond.setCustomNftURIByAdmin(omnichainId,"https://custom_uri.com");

        vm.stopPrank();
    }
    function test_setCustomNftURIByAdmin_ShouldSuccess() public {
        uint256 omnichainId = mintFacetAsDiamond.mint();
        string memory customUri = "https://custom_uri.com";

        vm.prank(owner);
        adminFacetAsDiamond.setCustomNftURIByAdmin(omnichainId,customUri);

        string memory actualTokenUri = mintFacetAsDiamond.tokenURI(omnichainId);
        assertEq(actualTokenUri, customUri);
    }
}
