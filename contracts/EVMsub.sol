// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EVMsub {

    using SafeERC20 for IERC20;
    using SafeMath for uint256; 

    // STORAGE

    struct Subscription {
        address owner;
        address payeeAddress;
        IERC20 payToken;
        uint amountRecurring;
        uint amountInitial;
        uint periodMultiplier;
        uint startTime;
        string data;
        bool active;
        uint nextPaymentTime;
    }

    mapping (bytes32 => Subscription) public subscriptions;
    mapping (address => bytes32[]) public subscribers_Subscriptions;

    // EVENTS (INDEXING)

    event NewSubscription(
        bytes32 _subscriptionID,
        address _payeeAddress,
        IERC20 _payToken,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodMultiplier,
        uint _startTime
    );

    event RenewedSubscription(
        bytes32 _subscriptionID,
        address _subscriber,
        uint _amountPaid
    );

    event CancelSubscription(
        bytes32 _subscriptionID,
        address _subscriber
    );

    /**
    * @dev Called by the subscriber on their own wallet, using data initiated by the merchant in a checkout flow.
    * @param _payeeAddress The address that will receive payments
    * @param _amountRecurring The maximum amount that can be paid in each subscription period
    * @param _amountInitial The amount to be paid immediately, can be lower than total allowable amount
    * @param _periodMultiplier The interval that must elapse before the next payment is due
    * @return A bytes32 for the created subscriptionId
    */

    function initSubscription(
        address _payeeAddress,
        IERC20 _payToken,
        uint _amountRecurring,
        uint _amountInitial,
        uint _periodMultiplier,
        string memory _data
        ) 
        public 
        returns (bytes32)
    {
        // Check if subscriber has a balance of at least the initial and first recurring payment
        uint amountRequired = _amountInitial.add(_amountRecurring);
        require((_payToken.balanceOf(msg.sender) >= amountRequired),
                "INSUFFICIENT BALANCE");
        
        //  Check if subscriber has approval for at least the initial and first recurring payment
        require((_payToken.allowance(msg.sender, address(this)) >= amountRequired),
                "INSUFFICIENT APPROVAL");

        // Initiating new subscription object
        Subscription memory subscription= Subscription({
            owner: msg.sender,
            payeeAddress: _payeeAddress,
            payToken: _payToken,
            amountRecurring: _amountRecurring,
            amountInitial: _amountInitial,
            periodMultiplier: _periodMultiplier,
            startTime: block.timestamp,
            data: _data,
            active: true,
            nextPaymentTime: block.timestamp.add(_periodMultiplier)
        });

        bytes32 subscriptionID = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number));
        subscriptions[subscriptionID] = subscription;

        subscribers_Subscriptions[msg.sender].push(subscriptionID);

        _payToken.safeTransferFrom(msg.sender, _payeeAddress, _amountInitial);

        // Emit NewSubscription event
        emit NewSubscription(
            subscriptionID,
            _payeeAddress,
            _payToken,
            _amountRecurring,
            _amountInitial,
            _periodMultiplier,
            block.timestamp
            );

        return subscriptionID;
    }

    /**
    * @dev Get all subscriptions for a subscriber address
    * @param _subscriber The address of the subscriber
    * @return An array of bytes32 values that map to subscriptions
    */
     function getSubscribersSubscriptions(address _subscriber)
        public
        view
        returns (bytes32[] memory)
    {
        return subscribers_Subscriptions[_subscriber];
    }

    /**
    * @dev Delete a subscription
    * @param  _subscriptionID The subscription ID to delete
    * @return true if the subscription has been deleted
    */
    function cancelSubscription(bytes32 _subscriptionID)
        public
        returns (bool)
    {
        Subscription storage subscription = subscriptions[_subscriptionID];
        require((subscription.payeeAddress == msg.sender)
            || (subscription.owner == msg.sender), "NOT SUBSCRIBER OR OWNER");

        delete subscriptions[_subscriptionID];
        emit CancelSubscription(_subscriptionID, msg.sender);
        return true;
    }


    /**
    * @dev Called by or on behalf of the merchant to find whether a subscription has a payment due
    * @param _subscriptionID The subscription ID to process payments for
    * @return A boolean to indicate whether a payment is due
    */
    function paymentDue(bytes32 _subscriptionID)
        public
        view
        returns (bool)
    {
        Subscription memory subscription = subscriptions[_subscriptionID];

        // Check this is an active subscription
        require((subscription.active == true), "Not an active subscription");

        // Check that subscription start time has passed
        require((subscription.startTime <= block.timestamp),
            "Subscription has not started yet");

        // Check whether required time interval has passed since last payment
        if (subscription.nextPaymentTime <= block.timestamp) {
            return true;
        }
        else {
            return false;
        }
    }


    /**
    * @dev Called by or on behalf of the merchant, in order to initiate a payment.
    * @param _subscriptionID The subscription ID to process payments for
    * @param _amount Amount to be transferred, can be lower than total allowable amount
    * @return A boolean to indicate whether the payment was successful
    */
    function renewSubscription(
        bytes32 _subscriptionID,
        uint _amount
        )
        public
        returns (bool)
    {
        Subscription storage subscription = subscriptions[_subscriptionID];

        require((_amount <= subscription.amountRecurring),
            "REQ AMOUNT HIGHER THAN ALLOWED");

        require((paymentDue(_subscriptionID)),
            "PAYMENT NOT DUE");

        IERC20 payToken = subscription.payToken;

        payToken.safeTransferFrom(subscription.owner, subscription.payeeAddress, _amount);

        // Increment subscription nextPaymentTime by one interval
        subscription.nextPaymentTime = subscription.nextPaymentTime.add(subscription.periodMultiplier);
        
        emit RenewedSubscription(_subscriptionID, msg.sender, _amount);
        return true;
    }

}
