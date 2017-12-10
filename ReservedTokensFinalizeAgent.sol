// Created using ICO Wizard https://github.com/oraclesorg/ico-wizard by Oracles Network
pragma solidity ^0.4.11;

import "./Ownable.sol";
import "./SMathLib.sol";
import "./CrowdsaleTokenExt.sol";
import "./MintedTokenCappedCrowdsaleExt.sol";


/**
 * The default behavior for the crowdsale end.
 *
 * Unlock tokens.
 */
contract ReservedTokensFinalizeAgent is FinalizeAgent {
    using SMathLib for uint;
    CrowdsaleTokenExt public token;
    CrowdsaleExt public crowdsale;

    function ReservedTokensFinalizeAgent(CrowdsaleTokenExt _token, CrowdsaleExt _crowdsale) {
        token = _token;
        crowdsale = _crowdsale;
    }

    /** Check that we can release the token */
    function isSane() public constant returns (bool) {
        return (token.releaseAgent() == address(this));
    }

    /** Called once by crowdsale finalize() if the sale was success. */
    function finalizeCrowdsale() public {
        if(msg.sender != address(crowdsale)) {
            throw;
        }

        // How many % of tokens the founders and others get
        uint tokensSold = crowdsale.tokensSold();

        // move reserved tokens in percentage
        for (var j = 0; j < token.reservedTokensDestinationsLen(); j++) {
            uint allocatedBonusInPercentage;
            uint percentsOfTokensUnit = token.getReservedTokensListValInPercentageUnit(token.reservedTokensDestinations(j));
            uint percentsOfTokensDecimals = token.getReservedTokensListValInPercentageDecimals(token.reservedTokensDestinations(j));
            if (percentsOfTokensUnit > 0) {
                allocatedBonusInPercentage = tokensSold * percentsOfTokensUnit / 10**percentsOfTokensDecimals / 100;
                tokensSold = tokensSold.plus(allocatedBonusInPercentage);
                token.mint(token.reservedTokensDestinations(j), allocatedBonusInPercentage);
            }
        }

        // move reserved tokens in tokens
        for (var i = 0; i < token.reservedTokensDestinationsLen(); i++) {
            uint allocatedBonusInTokens = token.getReservedTokensListValInTokens(token.reservedTokensDestinations(i));
            if (allocatedBonusInTokens > 0) {
                tokensSold = tokensSold.plus(allocatedBonusInTokens);
                token.mint(token.reservedTokensDestinations(i), allocatedBonusInTokens);
            }
        }

        token.releaseTokenTransfer();
    }

}
