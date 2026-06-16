# Error Handling & Resilience — Validation Checklist

## Timeouts and retries

- [ ] Every outbound dependency has an explicit timeout
- [ ] Retry policy targets transient errors only
- [ ] Retry count/backoff/jitter values are explicit and documented
- [ ] No unbounded retries

## Circuit breaking and load protection

- [ ] Circuit breaker is configured for critical remote dependencies
- [ ] Break duration and failure threshold are tuned from real telemetry
- [ ] Bulkhead/isolation strategy exists for expensive operations

## Idempotency and data safety

- [ ] Commands with side effects are idempotent or deduplicated
- [ ] Retry boundaries do not produce duplicate writes/notifications
- [ ] Transactional boundaries are explicit

## API error contracts

- [ ] Exceptions are mapped to consistent status codes
- [ ] API returns Problem Details payloads for failures
- [ ] Internal exception details are not leaked to clients

## Observability integration

- [ ] Retry/circuit events are logged and traced
- [ ] Alerting exists for elevated retry rate and open circuits
- [ ] Fallback path usage is measurable
