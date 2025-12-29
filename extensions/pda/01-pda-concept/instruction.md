# PDA Concept

This stage introduces Program Derived Addresses (PDAs), one of Solana's most
powerful features for secure account management. PDAs enable programs to
control accounts without private keys, forming the foundation of secure fund
custody in lending protocols.

## What is a Program Derived Address

A Program Derived Address is a public key derived deterministically from a
program ID and additional seed inputs. Unlike regular keypairs where a private
key controls the address, PDAs have no corresponding private key. Only the
program that derived them can sign on their behalf.

Regular addresses are Ed25519 curve points generated from private keys. PDAs
are derived differently—they exist off the curve and cannot be signed for by
any private key. This property makes them ideal for accounts that should only
be controlled by program logic.

When you derive a PDA, you provide seeds (byte arrays) and optionally a bump
seed. The derivation function combines your program ID, seeds, and bump to
generate the address. If the result happens to fall on the Ed25519 curve, you
must try a different bump value until you get an off-curve address.

## Why PDAs Matter for Lending Protocols

Lending protocols handle user funds and must ensure only authorized operations
occur. PDAs provide the security foundation for this trust.

Consider a treasury vault holding user deposits. If the vault were controlled
by a regular keypair, whoever held that keypair could steal all funds. Instead,
we make the treasury a PDA controlled by our lending program. Only our program
can authorize transfers from the treasury, and program logic enforces all
authorization rules.

PDAs also provide deterministic addressing. Given the same seeds, you always
derive the same address. This enables users to know in advance where their
bank or user position account will exist, even before it is created.

## PDA Derivation Process

Deriving a PDA involves trying different bump values until finding one that
produces an off-curve address:

```rust
use anchor_lang::prelude::*;

let (pda_address, bump) = Pubkey::find_program_address(
    &[
        b"bank",
        mint.key().as_ref(),
    ],
    program_id,
);
```

The `find_program_address` function handles the bump search automatically. It
tries bump values starting from 255 and descending, checking if each produces
an off-curve result. The first successful derivation returns the address and
the bump that worked.

## PDA Signing Authority

When a PDA needs to perform actions requiring authority (like token transfers),
the program provides signing seeds:

```rust
let seeds = &[
    b"treasury",
    mint.key().as_ref(),
    &[bank.bump],
];
let signer_seeds = [&seeds[..]];

let cpi_context = CpiContext::new_with_signer(
    token_program.to_account_info(),
    cpi_accounts,
    signer_seeds,
);
```

The runtime uses these seeds to reconstruct the PDA and sign on its behalf.
This is the magic that allows program-controlled accounts to authorize token
transfers.

## PDAs in Your Lending Protocol

Your lending protocol will use PDAs for several purposes:

- **Bank Account**: Derived from "bank" and mint address
- **User Account**: Derived from user wallet address
- **Treasury Account**: Derived from "treasury" and mint address

Each PDA ensures only your program can control these accounts.

## Practical Exercise

Use the `Pubkey::find_program_address` function to derive PDAs with different
seed combinations. Observe how changing any seed changes the resulting address.
Verify that the same inputs always produce the same output.

## Key Takeaways

PDAs are addresses derived from program ID and seeds without corresponding
private keys. Only the deriving program can control PDAs through provided seeds.
PDAs enable secure program-controlled treasuries and deterministic account
addressing. PDA signing via `CpiContext::new_with_signer` authorizes actions
on behalf of the PDA.
