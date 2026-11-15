# No telemetry beyond User-Agent, and bodies are never logged

Unlike Stripe, the SDKs write nothing to disk (no telemetry id), detect no AI
agents, send no client-telemetry headers and never log request or response
bodies, even at debug level. Bodies carry learner names and emails in a HIPAA
product. Logging is off by default; when on, it carries method, path, status,
latency and request id, with `Authorization` redacted. The only identifying
header is `User-Agent` (SDK, version, runtime and optional app info).
