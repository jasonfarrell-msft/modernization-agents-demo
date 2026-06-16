# Class Separation & Single Responsibility — Validation Checklist

## Class cohesion

- [ ] Each class has a single primary reason to change
- [ ] Business rules are not mixed with transport/controller code
- [ ] Infrastructure details (SQL, HTTP, file I/O) are isolated from domain classes

## Dependency shape

- [ ] Constructor dependency count is reasonable (typically <= 5)
- [ ] Dependency groups reflect one responsibility, not multiple modules
- [ ] No service locator access from business classes

## Layer boundaries

- [ ] Application layer coordinates workflows only
- [ ] Domain layer contains policies/rules and is infrastructure-agnostic
- [ ] Infrastructure layer implements ports/interfaces from inner layers

## Testability

- [ ] Domain rules are unit tested without framework dependencies
- [ ] Workflow orchestration tests verify collaboration between dependencies
- [ ] Infrastructure adapters are covered with focused integration tests
