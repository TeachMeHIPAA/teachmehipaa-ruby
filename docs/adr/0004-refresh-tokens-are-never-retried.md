# Refresh-token exchanges are never retried, and rotated tokens persist first

_Superseded 2026-11-15: partner Grants removed (TeachMeHIPAA/monorepo#2308)._

Every refresh returns a new Refresh token. Presenting any recent superseded
one revokes the whole Grant. So an SDK must not retry a `refresh_token` or
`authorization_code` exchange whose outcome is unknown, and it must save the
rotated Refresh token to the caller's `TokenStore` before it uses the new
Access token. Exchanges for one Grant run single-flight. That makes partner
auth fail closed on a network error at exactly the wrong moment: the caller
gets an error and must re-run consent if the store never received the new
token. The alternative, a silent retry, locks the partner out for certain.
