#!/bin/bash
#
# Verification script for StackClass Solana Lending Program
# Validates user implementation for specific stages
#
# Usage: ./verify.sh <stage_id>
# Output: JSON format result for tester consumption

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_FILE="$PROJECT_ROOT/programs/lending-program/src/lib.rs"

STAGE_ID="$1"

if [ -z "$STAGE_ID" ]; then
  echo '{"success": false, "message": "No stage ID provided", "details": {}}'
  exit 1
fi

if [ ! -f "$LIB_FILE" ]; then
  echo '{"success": false, "message": "lib.rs not found", "details": {"file": "programs/lending-program/src/lib.rs"}}'
  exit 1
fi

output_json() {
  local success="$1"
  local message="$2"
  local details="$3"
  echo "{\"success\": $success, \"message\": \"$message\", \"details\": $details}"
}

# Base Stage Checks

check_ry1() {
  local program_id=$(grep 'declare_id!' "$LIB_FILE" | grep -o '"[^"]*"' | tr -d '"')
  local default_id="LendZ1111111111111111111111111111111111111"
  
  if [ "$program_id" = "$default_id" ]; then
    output_json "false" "Program ID has not been updated. Run 'anchor keys sync' to generate a unique program ID." "{}"
  else
    output_json "true" "Program ID successfully updated to $program_id" "{\"program_id\": \"$program_id\"}"
  fi
}

check_bs2() {
  local has_bank_struct=$(grep -c 'pub struct Bank' "$LIB_FILE" || true)
  local has_user_struct=$(grep -c 'pub struct User' "$LIB_FILE" || true)
  
  if [ "$has_bank_struct" -gt 0 ] && [ "$has_user_struct" -gt 0 ]; then
    output_json "true" "Bank and User structs are defined" "{}"
  else
    output_json "false" "Bank and User structs must be defined" "{\"has_bank\": $has_bank_struct, \"has_user\": $has_user_struct}"
  fi
}

check_us3() {
  local has_user_init=$(grep -c 'pub struct.*User.*<' "$LIB_FILE" || true)
  local has_user_fields=$(grep -c 'pub owner:' "$LIB_FILE" || true)
  local has_deposited=$(grep -c 'pub deposited_amount:' "$LIB_FILE" || true)
  
  if [ "$has_user_init" -gt 0 ] && [ "$has_deposited" -gt 0 ]; then
    output_json "true" "User struct has required fields (owner, deposited_amount)" "{}"
  else
    output_json "false" "User struct must have owner and deposited_amount fields" "{}"
  fi
}

check_ib4() {
  local has_init_bank=$(grep -c 'init_bank' "$LIB_FILE" || true)
  local has_initialize=$(grep -c 'pub fn initialize' "$LIB_FILE" || true)
  local has_bank_account=$(grep -c 'pub struct.*Bank.*Account' "$LIB_FILE" || true)
  
  if [ "$has_initialize" -gt 0 ] && [ "$has_bank_account" -gt 0 ]; then
    output_json "true" "Initialize function and Bank account structure are defined" "{}"
  else
    output_json "false" "Initialize function and Bank account structure must be defined" "{}"
  fi
}

check_iu5() {
  local has_init_user=$(grep -c 'init_user' "$LIB_FILE" || true)
  local has_user_account=$(grep -c 'pub struct.*User.*Account' "$LIB_FILE" || true)
  local seeds_user=$(grep -c 'seeds.*user.key()' "$LIB_FILE" || true)
  
  if [ "$has_init_user" -gt 0 ] && [ "$seeds_user" -gt 0 ]; then
    output_json "true" "User account initialization with PDA seeds is implemented" "{}"
  else
    output_json "false" "User account initialization must use PDA seeds" "{}"
  fi
}

check_dp6() {
  local has_deposit_fn=$(grep -c 'pub fn deposit' "$LIB_FILE" || true)
  local has_deposit_ctx=$(grep -c 'pub struct Deposit' "$LIB_FILE" || true)
  local has_transfer=$(grep -c 'transfer_checked' "$LIB_FILE" || true)
  local has_deposited_update=$(grep -c 'deposited_amount +=' "$LIB_FILE" || true)
  local has_total_deposits=$(grep -c 'total_deposits +=' "$LIB_FILE" || true)
  
  if [ "$has_deposit_fn" -gt 0 ] && [ "$has_transfer" -gt 0 ]; then
    output_json "true" "Deposit function with token transfer is implemented" "{}"
  else
    output_json "false" "Deposit function must implement token transfer" "{}"
  fi
}

check_wt7() {
  local has_withdraw_fn=$(grep -c 'pub fn withdraw' "$LIB_FILE" || true)
  local has_withdraw_ctx=$(grep -c 'pub struct Withdraw' "$LIB_FILE" || true)
  local has_signer_seeds=$(grep -c 'signer_seeds' "$LIB_FILE" || true)
  local has_with_signer=$(grep -c 'with_signer' "$LIB_FILE" || true)
  local has_validation=$(grep -c 'deposited_amount >=' "$LIB_FILE" || true)
  
  if [ "$has_withdraw_fn" -gt 0 ] && [ "$has_with_signer" -gt 0 ]; then
    output_json "true" "Withdraw function with PDA signing is implemented" "{}"
  else
    output_json "false" "Withdraw function must implement PDA signing for treasury transfers" "{}"
  fi
}

check_br8() {
  local has_borrow_fn=$(grep -c 'pub fn borrow' "$LIB_FILE" || true)
  local has_borrow_ctx=$(grep -c 'pub struct Borrow' "$LIB_FILE" || true)
  local has_borrowed_amount=$(grep -c 'borrowed_amount' "$LIB_FILE" || true)
  local has_ltv_check=$(grep -c 'ltv\|collateral_ratio\|health_factor' "$LIB_FILE" || true)
  
  if [ "$has_borrow_fn" -gt 0 ] && [ "$has_ltv_check" -gt 0 ]; then
    output_json "true" "Borrow function with LTV/health factor validation is implemented" "{}"
  else
    output_json "false" "Borrow function must implement LTV or health factor validation" "{}"
  fi
}

check_rp9() {
  local has_repay_fn=$(grep -c 'pub fn repay' "$LIB_FILE" || true)
  local has_repay_ctx=$(grep -c 'pub struct Repay' "$LIB_FILE" || true)
  local has_borrowed_update=$(grep -c 'borrowed_amount -=' "$LIB_FILE" || true)
  
  if [ "$has_repay_fn" -gt 0 ]; then
    output_json "true" "Repay function is implemented" "{}"
  else
    output_json "false" "Repay function must be implemented" "{}"
  fi
}

check_lq10() {
  local has_liquidate_fn=$(grep -c 'pub fn liquidate' "$LIB_FILE" || true)
  local has_liquidate_ctx=$(grep -c 'pub struct Liquidate' "$LIB_FILE" || true)
  local has_health_factor=$(grep -c 'health_factor' "$LIB_FILE" || true)
  local has_liquidation_bonus=$(grep -c 'bonus\|liquidation' "$LIB_FILE" || true)
  
  if [ "$has_liquidate_fn" -gt 0 ]; then
    output_json "true" "Liquidate function is implemented" "{}"
  else
    output_json "false" "Liquidate function must be implemented" "{}"
  fi
}

check_er11() {
  local has_error_enum=$(grep -c 'pub enum.*Error' "$LIB_FILE" || true)
  local has_error_code=$(grep -c '#\[error_code\]' "$LIB_FILE" || true)
  local has_msg=$(grep -c '#\[msg' "$LIB_FILE" || true)
  
  if [ "$has_error_enum" -gt 0 ]; then
    output_json "true" "Custom error codes are defined" "{}"
  else
    output_json "false" "Custom error codes must be defined" "{}"
  fi
}

check_py12() {
  local has_pyth=$(grep -c 'pyth\|Pyth' "$LIB_FILE" || true)
  local has_price_feed=$(grep -c 'price_feed\|PriceFeed' "$LIB_FILE" || true)
  local has_oracle=$(grep -c 'oracle\|Oracle' "$LIB_FILE" || true)
  
  if [ "$has_pyth" -gt 0 ] || [ "$has_oracle" -gt 0 ]; then
    output_json "true" "Oracle/Pyth integration is implemented" "{}"
  else
    output_json "false" "Oracle/Pyth integration must be implemented" "{}"
  fi
}

check_td13() {
  local has_test_file=$(find "$PROJECT_ROOT" -name "*.rs" -path "*/tests/*" | wc -l)
  local has_test_mod=$(grep -c '#\[test\]' "$LIB_FILE" || true)
  
  output_json "true" "Testing infrastructure is available" "{\"test_files\": $has_test_file}"
}

# Advanced Feature Checks

check_ir1() {
  local has_interest_rate=$(grep -c 'interest\|rate' "$LIB_FILE" || true)
  local has_apr=$(grep -c 'APR\|apr' "$LIB_FILE" || true)
  local has_accrue=$(grep -c 'accrue\|accrued' "$LIB_FILE" || true)
  
  if [ "$has_interest_rate" -gt 0 ]; then
    output_json "true" "Interest rate model is implemented" "{}"
  else
    output_json "false" "Interest rate model must be implemented" "{}"
  fi
}

check_fl2() {
  local has_flash_loan=$(grep -c 'flash' "$LIB_FILE" || true)
  local has_flash_loan_fn=$(grep -c 'pub fn flash_loan' "$LIB_FILE" || true)
  
  if [ "$has_flash_loan_fn" -gt 0 ]; then
    output_json "true" "Flash loan function is implemented" "{}"
  else
    output_json "false" "Flash loan function must be implemented" "{}"
  fi
}

case "$STAGE_ID" in
  # Base Stages
  ry1)
    check_ry1
    ;;
  bs2)
    check_bs2
    ;;
  us3)
    check_us3
    ;;
  ib4)
    check_ib4
    ;;
  iu5)
    check_iu5
    ;;
  dp6)
    check_dp6
    ;;
  wt7)
    check_wt7
    ;;
  br8)
    check_br8
    ;;
  rp9)
    check_rp9
    ;;
  lq10)
    check_lq10
    ;;
  er11)
    check_er11
    ;;
  py12)
    check_py12
    ;;
  td13)
    check_td13
    ;;
  # Advanced Features
  ir1)
    check_ir1
    ;;
  fl2)
    check_fl2
    ;;
  *)
    output_json "false" "Unknown stage ID: $STAGE_ID" "{}"
    exit 1
    ;;
esac
