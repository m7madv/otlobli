# Account deletion report — v86.208

Static review confirms deletion is initiated in Profile, requires the in-app
action plus a second irreversible `confirm`, and calls the authenticated
`account-lifecycle` function. The server first validates the session, revokes
stored Apple authorizations when configured, then executes the database
deletion transaction.

The migration makes deletion idempotent, invalidates active sessions and push
installations, removes identities/authorization records, clears profile/address
data, and anonymizes retained order/payment transaction ownership rather than
deleting legally relevant records. Direct table access is revoked and RLS is
enabled. Invalid-session smoke testing returned 401.

No destructive test was run because no dedicated disposable account was
authorized. End-to-end session rejection, push detachment, address/profile
removal, Apple revocation, retained-order anonymization, and re-login behavior
remain physically/backend-test pending.

