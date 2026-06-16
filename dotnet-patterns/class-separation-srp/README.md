# Class Separation & Single Responsibility

## Overview

Single Responsibility Principle (SRP) means each class has one reason to change. In modernization work, SRP helps separate orchestration, business rules, and infrastructure concerns so services stay testable and evolvable.

## Problem

Legacy services often accumulate "god classes" that validate input, execute domain rules, call external systems, and format responses in one place. Changes become risky and regressions increase.

## Solution

Split responsibilities into focused units:
- **Application/orchestration** coordinates workflows.
- **Domain services/entities** enforce business rules.
- **Infrastructure adapters** handle external systems.

Limit constructor dependencies and move cross-cutting concerns (logging, retries, validation) to middleware/pipelines.

## Benefits

- Smaller, easier-to-review classes
- Better unit test isolation
- Cleaner boundaries for future refactoring

## Tradeoffs

- More files and interfaces
- Requires discipline to keep boundaries intact

## When to Use

- Any class with high churn, many dependencies, or mixed concerns
- Services being split for containerized deployment

## When NOT to Use

- Tiny classes that are already cohesive and stable

## Implementation Steps

1. Identify classes with multiple reasons to change.
2. Separate orchestration from domain decisions.
3. Move infrastructure calls behind interfaces/adapters.
4. Reduce constructor dependency count by splitting responsibilities.
5. Verify each class can be tested with focused unit tests.

## Code Example

See [`examples/`](./examples/):
- `Before_OrderService.cs` - mixed responsibilities in one class.
- `After_OrderWorkflow.cs` - orchestration-only workflow.
- `After_OrderPolicy.cs` - isolated domain rule evaluation.

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- https://learn.microsoft.com/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
- https://learn.microsoft.com/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/
