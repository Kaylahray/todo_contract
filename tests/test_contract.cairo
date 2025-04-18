use todo::todo::{ ITodoListDispatcher, ITodoListSafeDispatcher, ITodoListSafeDispatcherTrait, ITodoListDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;

pub fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
pub fn CHIOMA() -> ContractAddress {
    'CHIOMA'.try_into().unwrap()
}

fn deploy_contract(initial_count: u64) -> ContractAddress {
    let class_hash = declare("TodoList").unwrap().contract_class();
    let mut calldata = array![];
    OWNER().serialize(ref calldata);
    initial_count.serialize(ref calldata);
    let (contract_address, _) = class_hash.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_initial_task_count_respected() {
    let contract_address = deploy_contract(3);
    let todo = ITodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_id = todo.add_task('Should start at ID 4');
    stop_cheat_caller_address(contract_address);
    assert!(task_id == 4, "Task ID must begin at 4 because of initial count");
}

#[test]
fn test_add_task_owner() {
    let contract_address = deploy_contract(0);
    let todo = ITodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_id = todo.add_task('Submit final project');
    stop_cheat_caller_address(contract_address);
    assert!(task_id == 1, "Task ID expected to be 1");
}

#[test]
#[feature("safe_dispatcher")]
fn test_add_task_not_owner() {
    let contract_address = deploy_contract(0);
    let todo = ITodoListSafeDispatcher { contract_address };
    start_cheat_caller_address(contract_address, CHIOMA());
    let result = todo.add_task('I am not authorized');
    stop_cheat_caller_address(contract_address);
    assert!(result.is_err(), "Not allowed to add task because you are not owner");
}

#[test]
fn test_complete_task () {
    let contract_address = deploy_contract(0);
    let todo = ITodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_id = todo.add_task('Complete your cleanup');
    todo.complete_task(task_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_delete_task() {
    let contract_address = deploy_contract(0);
    let todo = ITodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_id = todo.add_task('Remove outdated logs');
    todo.delete_task(task_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_delete_task_not_owner() {
    let contract_address = deploy_contract(0);
    let todo = ITodoListSafeDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    let task_id_result = todo.add_task('Prepare weekend summary');
    assert!(task_id_result.is_ok(), "Owner should be able to create task");
    let task_id = task_id_result.unwrap();
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, CHIOMA());
    let result = todo.delete_task(task_id);
    stop_cheat_caller_address(contract_address);
    assert!(result.is_err(), "User without permission cannot delete task");
}

#[test]
fn test_get_all_tasks() {
    let contract_address = deploy_contract(0);
    let todo = ITodoListDispatcher { contract_address };
    start_cheat_caller_address(contract_address, OWNER());
    todo.add_task('This remains');
    todo.add_task('This is deleted');
    todo.delete_task(2);
    let tasks = todo.get_all_tasks();
    stop_cheat_caller_address(contract_address);
    assert!(tasks.len() == 1, "Result length is incorrect");
}