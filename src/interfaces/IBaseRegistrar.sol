// import "../registry/ENS.sol";
// import "./IBaseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBaseRegistrar is IERC721 {


    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view returns (uint256);

   
}