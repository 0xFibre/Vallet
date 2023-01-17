module vallet::coin {
    use std::ascii;
    use std::type_name;
    use std::vector;

    use sui::pay;
    use sui::coin::{Self, Coin};
    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{TxContext};
    use sui::transfer;

    use vallet::safe::{Self, Safe};
    use vallet::error;

    friend vallet::main;
    friend vallet::transaction;

    public(friend) fun deposit<T>(safe: &mut Safe, payment: vector<Coin<T>>, amount: u64, ctx: &mut TxContext) {
        let coin = vector::pop_back(&mut payment);
        
        pay::join_vec(&mut coin, payment);

        let split_coin = coin::split(&mut coin, amount, ctx);

        if(coin::value(&coin) == 0) {
            coin::destroy_zero(coin);
        } else {
            pay::keep(coin, ctx);
        };

        internal_deposit(safe, split_coin);
    }

    public(friend) fun withdraw<T>(safe: &mut Safe, amount: u64, recipient: address, ctx: &mut TxContext) {
        let withdrawal_coin = internal_withdrawal<T>(safe, amount, ctx);
        transfer::transfer(withdrawal_coin, recipient);
    }

    fun internal_deposit<T>(safe: &mut Safe, new_coin: Coin<T>) {
        let coin_type = ascii::into_bytes(type_name::into_string(type_name::get<T>()));
        let safe_id = safe::borrow_uid_mut(safe);

        if(ofield::exists_with_type<vector<u8>, Coin<T>>(safe_id, coin_type)) {
            let coin = ofield::borrow_mut<vector<u8>, Coin<T>>(safe_id, coin_type);
            coin::join(coin, new_coin);
        } else {
            ofield::add<vector<u8>, Coin<T>>(safe_id, coin_type, new_coin);
        }
    }

    fun internal_withdrawal<T>(safe: &mut Safe, amount: u64, ctx: &mut TxContext): Coin<T> {
        let coin_type = ascii::into_bytes(type_name::into_string(type_name::get<T>()));
        let safe_id = safe::borrow_uid_mut(safe);

        assert!(ofield::exists_with_type<vector<u8>, Coin<T>>(safe_id, coin_type), error::coin_not_found());
 
        let coin = ofield::borrow_mut<vector<u8>, Coin<T>>(safe_id, coin_type);
        coin::split(coin, amount, ctx)
    }
}