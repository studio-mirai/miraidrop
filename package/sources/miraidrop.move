module miraidrop::miraidrop;

use std::string::String;
use std::type_name::{Self};
use std::u64::{Self};

use sui::event;
use sui::linked_table::{Self, LinkedTable};
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};

public struct MiraiDrop<phantom T> has key, store {
    id: UID,
    // Coin balance to airdrop.
    balance: Balance<T>,
    // Total balance allocated to recipients.
    balance_allocated: u64,
    // Whether the airdrop has been initialized.
    // Recipients and balances can't be modified after initialization.
    is_initialized: bool,
    // Recipients and their allocated balances.
    recipients: LinkedTable<address, u64>,
}

public struct MiraiDropCreatedEvent has copy, drop {
    miraidrop_id: ID,
    type_name: String,
}

public fun new<T: drop>(
    ctx: &mut TxContext,
): MiraiDrop<T> {
    let miraidrop = MiraiDrop<T> {
        id: object::new(ctx),
        balance: balance::zero<T>(),
        balance_allocated: 0,
        is_initialized: false,
        recipients: linked_table::new(ctx),
    };

    event::emit(
        MiraiDropCreatedEvent {
            miraidrop_id: object::id(&miraidrop),
            type_name: type_name::get<T>().into_string().to_string(),
        }
    );

    miraidrop
}

public fun deposit<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    coin: Coin<T>,
) {
    assert!(miraidrop.is_initialized == false, 1);

    miraidrop.balance.join(coin.into_balance());
}

public fun withdraw<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    amount: u64,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.is_initialized == false, 1);

    let balance = miraidrop.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

    coin
}

public fun withdraw_all<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.is_initialized == false, 1);

    let balance = miraidrop.balance.withdraw_all();
    let coin = coin::from_balance(balance, ctx);

    coin
}

public fun initialize<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
) {
    assert!(miraidrop.balance.value() == miraidrop.balance_allocated, 1);
    
    miraidrop.is_initialized = true;
}

public fun add_recipient<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    recipient: address,
    amount: u64,
) {
    assert!(!miraidrop.recipients.contains(recipient), 1);

    miraidrop.recipients.push_back(recipient, amount);
    miraidrop.balance_allocated = miraidrop.balance_allocated + amount;
}

// Remove a specific recipient, and return the allocated balance as a coin.
public fun remove_recipient<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    recipient: address,
    ctx: &mut TxContext,
): Coin<T> {
    assert!(miraidrop.is_initialized == false, 1);

    let amount = miraidrop.recipients.remove(recipient);
    miraidrop.balance_allocated = miraidrop.balance_allocated - amount;

    let balance = miraidrop.balance.split(amount);
    let coin = coin::from_balance(balance, ctx);

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
        let (_, amount) = miraidrop.recipients.pop_back();
        miraidrop.balance_allocated = miraidrop.balance_allocated - amount;

        let balance = miraidrop.balance.split(amount);
        withdraw_balance.join(balance);

        i = i + 1;
    };

    let coin = coin::from_balance(withdraw_balance, ctx);

    coin
}

public fun destroy_empty<T: drop>(
    miraidrop: MiraiDrop<T>,
) {
    assert!(miraidrop.is_initialized == true, 1);
    assert!(miraidrop.balance.value() == 0, 2);

    let MiraiDrop {
        id,
        balance,
        recipients,
        ..
    } = miraidrop;

    id.delete();
    balance.destroy_zero();
    recipients.destroy_empty();
}

// Batch execute airdrop to multiple recipients.
public fun execute<T: drop>(
    miraidrop: &mut MiraiDrop<T>,
    mut batch_size: u64,
    ctx: &mut TxContext,
) {
    assert!(miraidrop.is_initialized == true, 1);

    batch_size = u64::min(batch_size, miraidrop.recipients.length());

    let mut i = 0;
    while (i < batch_size) {
        let (recipient, amount) = miraidrop.recipients.pop_back();
        let balance = miraidrop.balance.split(amount);
        let coin = coin::from_balance(balance, ctx);
        transfer::public_transfer(coin, recipient);
        
        i = i + 1;
    };
}