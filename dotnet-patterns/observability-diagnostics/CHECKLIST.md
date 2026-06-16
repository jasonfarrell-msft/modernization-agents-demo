# Observability & Diagnostics — Validation Checklist

## Logging

- [ ] Logs are structured (JSON or key/value), not free-form strings only
- [ ] Every log event includes correlation/trace identifiers
- [ ] Error logs include operation name and dependency context
- [ ] PII/secrets are excluded or redacted

## Tracing

- [ ] OpenTelemetry tracing enabled for inbound requests
- [ ] Outbound HTTP/database operations participate in the same trace
- [ ] Custom spans added for high-value business operations
- [ ] Trace sampling strategy is explicit and documented

## Metrics

- [ ] RED metrics (rate, errors, duration) emitted for primary endpoints/jobs
- [ ] Dependency failure and latency metrics are available
- [ ] Metrics have stable, low-cardinality dimensions

## Health and readiness

- [ ] Liveness endpoint checks process viability only
- [ ] Readiness endpoint checks critical dependencies
- [ ] OpenShift probes are configured against the correct endpoints

## Operations

- [ ] Alert thresholds are defined for error rate and latency
- [ ] Dashboards exist for service-level and dependency-level telemetry
- [ ] Runbook links are attached to alerts
