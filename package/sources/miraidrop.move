// Copyright (c) Studio Mirai, Inc.
// SPDX-License-Identifier: MIT

module miraidrop::miraidrop;

use std::string::String;
use std::type_name::{Self};
use std::u64::{Self};

use sui::event;
use sui::linked_table::{Self, LinkedTable};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};

public struct MiraiDrop<phantom T> has key {
    id: UID,
    // Coin balance to airdrop.
    balance: Balance<T>,
    // Total balance allocated to recipients.
    balance_allocated: u64,
    // Airdrop lifecycle.
    lifecycle: Lifecycle,
    // Recipients and their allocated balances.
    recipients: LinkedTable<address, u64>,
}

public struct Lifecycle has store {
    // Whether the airdrop has been initialized.
    is_initialized: bool,
    // Whether the airdrop execution has been started.
    is_execution_started: bool,
    // Whether the airdrop execution has been completed.
    is_execution_completed: bool,
}

public struct CreatedEvent has copy, drop {
    miraidrop_id: ID,
    type_name: String,
}

public struct DepositEvent has copy, drop {
    miraidrop_id: ID,
    amount: u64,
}

public struct InitializeEvent has copy, drop {
    miraidrop_id: ID,
}

public struct WithdrawEvent has copy, drop {
    miraidrop_id: ID,
    amount: u64,
}

public struct RecipientAddedEvent has copy, drop {
    miraidrop_id: ID,
    recipient: address,
    amount: u64,
}

public struct RecipientRemovedEvent has copy, drop {
    miraidrop_id: ID,
    recipient: address,
    amount: u64,
}

public struct UninitializeEvent has copy, drop {
    miraidrop_id: ID,
}

public struct ExecutedEvent has copy, drop {
    miraidrop_id: ID,
    recipient: address,
    amount: u64,
}

const EAlreadyInitialized: u64 = 0;
const ENoExcessBalance: u64 = 1;
const ERecipientAlreadyExists: u64 = 2;
const EIncorrectBalance: u64 = 3;
const ENotInitialized: u64 = 4;
const EExecutionStarted: u64 = 5;
const EExecuteIncomplete: u64 = 6;

// Create a new airdrop. Requires a coin/balance type to be specified.
public fun new<T: drop>(
    ctx: &mut TxContext,
): MiraiDrop<T> {
    let lifecycle = Lifecycle {
        is_initialized: false,
        is_execution_started: false,
        is_execution_completed: false,
    };

    let miraidrop = MiraiDrop<T> {
        id: object::new(ctx),
        balance: balance::zero<T>(),
        balance_allocated: 0,
        lifecycle: lifecycle,
        recipients: linked_table::new(ctx),
    };

    event::emit(
        CreatedEvent {
            miraidrop_id: object::id(&miraidrop),
            type_name: type_name::get<T>().into_string().to_string(),
        }
    );

    miraidrop
}

// Add funds to the airdrop balance.
public fun deposit<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    coin: Coin<T>,
) {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);

    event::emit(
        DepositEvent {
            miraidrop_id: miraidrop.id(),
            amount: coin.value(),
        }
    );

    miraidrop.balance.join(coin.into_balance());
}

// Withdraw funds from the airdrop balance.
public fun withdraw<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);

    let balance = miraidrop.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

    event::emit(
        WithdrawEvent {
            miraidrop_id: miraidrop.id(),
            amount: coin.value(),
        }
    );

    coin
}

// Withdraw all funds from the airdrop balance.
public fun withdraw_all<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);

    let balance = miraidrop.balance.withdraw_all();
    let coin = coin::from_balance(balance, ctx);

    event::emit(
        WithdrawEvent {
            miraidrop_id: miraidrop.id(),
            amount: coin.value(),
        }
    );

    coin
}

// Withdraw the excess balance from the airdrop balance.
public fun withdraw_excess<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);
    assert!(miraidrop.balance.value() > miraidrop.balance_allocated, ENoExcessBalance);

    let excess_amount = miraidrop.balance.value() - miraidrop.balance_allocated;
    let balance = miraidrop.balance.split(excess_amount);
    let coin = coin::from_balance(balance, ctx);

    event::emit(
        WithdrawEvent {
            miraidrop_id: miraidrop.id(),
            amount: coin.value(),
        }
    );

    coin
}

// Add a recipient to the airdrop.
public fun add_recipient<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    recipient: address,
    amount: u64,
) {
    assert!(!miraidrop.recipients.contains(recipient), ERecipientAlreadyExists);

    event::emit(
        RecipientAddedEvent {
            miraidrop_id: miraidrop.id(),
            recipient: recipient,
            amount: amount,
        }
    );

    miraidrop.recipients.push_back(recipient, amount);
    miraidrop.balance_allocated = miraidrop.balance_allocated + amount;
}

// Remove a specific recipient, and return the allocated balance as a coin.
public fun remove_recipient<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    recipient: address,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);

    let amount = miraidrop.recipients.remove(recipient);
    miraidrop.balance_allocated = miraidrop.balance_allocated - amount;

    let balance = miraidrop.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

    event::emit(
        RecipientRemovedEvent {
            miraidrop_id: miraidrop.id(),
            recipient: recipient,
            amount: coin.value(),
        }
    );

    coin
}

// Batch remove multiple recipients, and return the aggregated balance as a coin.
public fun remove_recipients<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    mut batch_size: u64,
    ctx: &mut TxContext,
): Coin<T> {
    batch_size = u64::min(batch_size, miraidrop.recipients.length());
    
    let mut withdraw_balance = balance::zero<T>();

    let mut i = 0;
    while (i < batch_size) {
        let (recipient, amount) = miraidrop.recipients.pop_back();
        miraidrop.balance_allocated = miraidrop.balance_allocated - amount;

        let balance = miraidrop.balance.split(amount);

        event::emit(
            RecipientRemovedEvent {
                miraidrop_id: miraidrop.id(),
                recipient: recipient,
                amount: balance.value(),
            }
        );
    
        withdraw_balance.join(balance);

        i = i + 1;
    };

    let coin = coin::from_balance(withdraw_balance, ctx);

    coin
}

// Initialize the airdrop. After initialization, the airdrop balance can't be modified.
public fun initialize<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
) {
    assert!(miraidrop.lifecycle.is_initialized == false, EAlreadyInitialized);
    assert!(miraidrop.balance.value() == miraidrop.balance_allocated, EIncorrectBalance);

    event::emit(
        InitializeEvent {
            miraidrop_id: miraidrop.id(),
        }
    );

    miraidrop.lifecycle.is_initialized = true;
}

// Uninitialize the airdrop. Can only be called before the airdrop execution starts.
public fun uninitialize<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
) {
    assert!(miraidrop.lifecycle.is_initialized == true, ENotInitialized);
    assert!(miraidrop.lifecycle.is_execution_started == false, EExecutionStarted);

    event::emit(
        UninitializeEvent {
            miraidrop_id: miraidrop.id(),
        }
    );

    miraidrop.lifecycle.is_initialized = false;
}

// Destory MiraiDrop object after airdrop execution.
public fun destroy_empty<T: drop>(
    miraidrop: MiraiDrop<T>,
) {
    assert!(miraidrop.lifecycle.is_execution_completed == true, EExecuteIncomplete);

    let MiraiDrop {
        id,
        balance,
        lifecycle,
        recipients,
        ..
    } = miraidrop;

    id.delete();
    balance.destroy_zero();
    recipients.destroy_empty();

    let Lifecycle {..} = lifecycle;
}

// Batch execute airdrop to multiple recipients.
public fun execute<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    mut batch_size: u64,
    ctx: &mut TxContext,
) {
    assert!(miraidrop.lifecycle.is_initialized == true, ENotInitialized);

    if (miraidrop.lifecycle.is_execution_started == false) {
        miraidrop.lifecycle.is_execution_started = true;
    };

    batch_size = u64::min(batch_size, miraidrop.recipients.length());

    let mut i = 0;
    while (i < batch_size) {
        let (recipient, amount) = miraidrop.recipients.pop_back();
        
        let balance = miraidrop.balance.split(amount);
        let coin = coin::from_balance(balance, ctx);

        event::emit(
            ExecutedEvent {
                miraidrop_id: miraidrop.id(),
                recipient: recipient,
                amount: coin.value(),
            }
        );

        transfer::public_transfer(coin, recipient);
        
        i = i + 1;
    };

    if (miraidrop.recipients.length() == 0) {
        miraidrop.lifecycle.is_execution_completed = true;
    };
}

public fun transfer<T: drop>(
    miraidrop: MiraiDrop<T>,
    recipient: address,
) {
    transfer::transfer(miraidrop, recipient);
}

public fun id<T: drop>(
    miraidrop: &MiraiDrop<T>,
): ID {
    object::id(miraidrop)
}