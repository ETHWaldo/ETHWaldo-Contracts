// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./IETHWaldo.sol";

contract FunctionsConsumer is FunctionsClient, ConfirmedOwner {
    using Functions for Functions.Request;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    IETHWaldo public ethWaldo;
    mapping(bytes32 => uint256) public dealIds;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

    constructor(address oracle) FunctionsClient(oracle) ConfirmedOwner(msg.sender) {}

    function executeRequest(
        string calldata source,
        bytes calldata secrets,
        string[] calldata args,
        uint64 subscriptionId,
        uint32 gasLimit,
        uint256 dealId
    ) public onlyOwner returns (bytes32) {
        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
        if (secrets.length > 0) {
            req.addRemoteSecrets(secrets);
        }
        if (args.length > 0) req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
        latestRequestId = assignedReqID;
        dealIds[assignedReqID] = dealId;

        return assignedReqID;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) {
            latestError = err;
        } else {
            latestResponse = response;
            uint256 views = abi.decode(response, (uint256));
            uint256 dealId = dealIds[requestId];
            ethWaldo.setReadyToRelease(dealId, views);
        }

        emit OCRResponse(requestId, response, err);
        delete dealIds[requestId];
    }

    function updateOracleAddress(address oracle) public onlyOwner {
        setOracle(oracle);
    }

    function addSimulatedRequestId(address oracleAddress, bytes32 requestId) public onlyOwner {
        addExternalRequest(oracleAddress, requestId);
    }

    function setETHWaldo(address _ethWaldo) public onlyOwner {
        ethWaldo = IETHWaldo(_ethWaldo);
    }
}
