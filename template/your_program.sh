#!/bin/bash
#
# Use this script to run your program LOCALLY.
#
# Note: Changing this script WILL NOT affect how StackClass runs your program.
#
# Learn more: https://docs.stackclass.dev/challenges/program-interface

set -e # Exit early if any commands fail

# Copied from .stackclass/compile.sh
#
# - Edit this to change how your program compiles locally
# - Edit .stackclass/compile.sh to change how your program compiles remotely
(
  cd "$(dirname "$0")" # Ensure compile steps are run within the repository directory
  cargo build --release
)

# Check mode: validate user implementation for a specific stage
if [ "$1" = "--check" ]; then
  STAGE_ID="$2"
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  exec bash "$SCRIPT_DIR/.stackclass/verify.sh" "$STAGE_ID"
fi

# Copied from .stackclass/run.sh
#
# - Edit this to change how your program runs locally
# - Edit .stackclass/run.sh to change how your program runs remotely
exec target/release/stackclass-solana-lending-program "$@"
