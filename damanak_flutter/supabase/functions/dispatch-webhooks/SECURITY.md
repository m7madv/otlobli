# Webhook delivery network guard

`dispatch-webhooks` accepts only HTTPS endpoints on port `443`. Immediately
before sending, it resolves both `A` and `AAAA` records with a bounded timeout
and rejects the delivery if any returned address is private, loopback,
link-local, multicast, documentation-only, benchmarking, or otherwise reserved.
Redirects remain disabled.

Address classification follows the IANA
[IPv4](https://www.iana.org/assignments/iana-ipv4-special-registry/) and
[IPv6](https://www.iana.org/assignments/iana-ipv6-special-registry/)
special-purpose registries. IPv6 destinations outside the currently assigned
global-unicast `2000::/3` space are rejected as reserved. The parent `2001::/23`
IETF-assignment block is also rejected conservatively, including its uncommon
globally reachable exceptions, so an ordinary webhook endpoint must use regular
global-unicast hosting.

This is a fail-closed DNS screening layer, not complete DNS-rebinding
protection. `fetch()` performs a separate DNS lookup, so an attacker-controlled
hostname can theoretically change between validation and connection (a TOCTOU
window). Fully closing that gap requires an egress proxy that validates and pins
the destination IP, or equivalent socket-level IP pinning in the runtime.
