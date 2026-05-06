# User Role Audit

This document tracks the current usage of `User.role` in the codebase to distinguish between platform/operator concerns and product context.

## Current Roles
- `viewer`: Default role for new users. Represents a person who receives disclosures.
- `owner`: Represents a person who discloses information through a vault.
- `operator`: Represents a platform staff member with limited admin access.
- `admin`: Represents a platform administrator with full access to the console.

## Usage Audit

| File | Usage | Type | Recommendation |
|---|---|---|---|
| `app/controllers/console/dashboard_controller.rb` | Counts admins for stats. | Platform/Operator | Keep as platform concern. |
| `app/controllers/console/users_controller.rb` | Permits role in params. | Platform/Operator | Keep for console, but move product logic away. |
| `app/models/user.rb` | Defines `ROLES` and validates inclusion. | Both | Split into account capabilities and platform roles. |
| `app/views/console/users/*` | Displays and edits roles. | Platform/Operator | Keep as operator view. |

## Refactor Plan

### Platform/Operator Concerns (Keep in `User.role`)
- `admin`: Full system access.
- `operator`: Limited system access (support/compliance).

### Product Context (Move to Relationships/Capabilities)
- `owner`: This is not a role, but a relationship to a `Vault`. If a user owns a vault, they are an "owner" of that vault.
- `viewer`: This is not a role, but a relationship to a `Vault`. If a user has a `Permission` for a vault, they are a "viewer" of that vault.

### New Capability Fields (Proposed)
- `can_create_vault`: Boolean. Defaults to true for now.
- `bkc_access`: Boolean. Whether the user can access the BKC dashboard for their own vault.
- `account_status`: Replacing `status` with more descriptive states if needed, or keeping `status`.
- `is_beta_tester`: Boolean flag for early access.
