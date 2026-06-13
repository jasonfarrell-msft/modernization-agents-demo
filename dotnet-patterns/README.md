# .NET Patterns Repository

Central repository of proven architectural patterns and best practices for the eShop modernization initiative.

## 📚 Pattern Categories

### [Clean Architecture](./clean-architecture/)
Organizing code into distinct layers (Presentation → Application → Domain → Infrastructure) with clear separation of concerns.
- Project structure guidelines
- Layer responsibilities
- Dependency flow rules
- Testing approach

### [SOLID Principles](./solid-principles/)
Five principles for maintainable, flexible object-oriented design.
- **S**ingle Responsibility Principle
- **O**pen/Closed Principle
- **L**iskov Substitution Principle
- **I**nterface Segregation Principle
- **D**ependency Inversion Principle

### [Async Patterns](./async-patterns/)
Modern async/await best practices for non-blocking operations.
- Async all the way
- Cancellation token handling
- Exception handling in async code
- Performance considerations

### [Dependency Injection](./dependency-injection/)
Using DI containers for loose coupling and testability.
- Service lifetimes (Singleton, Scoped, Transient)
- Factory patterns
- Keyed services
- Testing with mocks

### [Testing Patterns](./testing-patterns/)
Comprehensive unit and integration testing strategies.
- Unit test structure (Arrange-Act-Assert)
- Mocking and isolation
- Test fixtures and builders
- Integration testing

### [API Design](./api-design/)
RESTful API best practices.
- Resource naming conventions
- Error response formats
- Versioning strategies
- Pagination and filtering

---

## 🎯 How to Use These Patterns

### For Individual Developers (Path 1: VSCode Agent)
1. Open a file needing improvement
2. Check relevant pattern category here
3. Review the pattern documentation
4. Apply suggestions with VSCode Modernization Agent
5. Validate against pattern's checklist

### For Architectural Changes (Path 2: Frontier Model)
1. Analyze service with Improve skill
2. Identify applicable patterns from this repository
3. Create implementation plan based on patterns
4. Execute coordinated changes
5. Validate against all relevant patterns

---

## 📋 Pattern Template

Each pattern follows this structure:

```markdown
# [Pattern Name]

## Overview
Brief description of what the pattern solves

## Problem
What pain point does this address?

## Solution
How does this pattern solve it?

## Benefits
Advantages of using this pattern

## Tradeoffs
What are the drawbacks?

## When to Use
Specific scenarios for this pattern

## When NOT to Use
Scenarios where this pattern is inappropriate

## Implementation Steps
1. Step 1
2. Step 2
3. Step 3

## Code Example
Before/after code showing the pattern

## Validation Checklist
- [ ] Item 1
- [ ] Item 2
- [ ] Item 3

## References
- Link 1
- Link 2
```

---

## ✅ Validation Checklists

Each pattern includes a validation checklist. Use these to verify pattern application:

```bash
# Example: Clean Architecture Checklist
- [ ] Project organized into Presentation/Application/Domain/Infrastructure layers
- [ ] Dependencies flow only inward
- [ ] Domain layer has no external dependencies
- [ ] Application layer depends only on Domain
- [ ] Infrastructure implements interfaces defined in Application
- [ ] Unit tests isolate each layer
- [ ] Integration tests verify layer interactions
```

---

## 🔄 Adding New Patterns

When a new pattern emerges:

1. Create a new directory: `dotnet-patterns/[pattern-name]/`
2. Add `README.md` following the pattern template
3. Add example code in `examples/` subdirectory
4. Create `CHECKLIST.md` for validation
5. Update this index (patterns-index.md)
6. Review with Technical Leadership

---

## 📊 Pattern Adoption Tracking

As you apply patterns, update the adoption matrix:

| Service | Clean Arch | SOLID | Async | DI | Testing | API Design |
|---------|-----------|-------|-------|----|---------|----|
| Catalog.API | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |
| Basket.API | 🟡 | 🟡 | 🟡 | 🔴 | 🟡 | 🟢 |
| Ordering.API | 🔴 | 🔴 | 🔴 | 🔴 | 🔴 | 🟢 |
| Identity.API | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 |
| WebApp | 🟡 | 🟡 | 🟢 | 🟡 | 🟡 | N/A |

Legend:
- 🟢 Fully adopted
- 🟡 Partially adopted
- 🔴 Not yet adopted

---

## 🚀 Quick Start

1. **Choose a pattern:** Browse categories above
2. **Read the documentation:** Understand problem/solution
3. **Review examples:** Study before/after code
4. **Apply to your code:** Follow implementation steps
5. **Validate:** Use the checklist

---

## 📞 Questions?

- 📖 Review pattern documentation
- 🔍 Check examples in pattern directory
- 💬 Ask at team sync
- 📝 Create issue if pattern is unclear or missing

---

**Last Updated:** June 11, 2026  
**Maintained By:** Architecture Team  
**Status:** Active Expansion (Adding patterns weekly)
