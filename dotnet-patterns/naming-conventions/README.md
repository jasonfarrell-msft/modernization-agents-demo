# Naming Conventions & Code Organization

## Overview

Consistent naming and organization reduce cognitive load across teams and speed up code reviews, onboarding, and modernization refactoring.

## Problem

Inconsistent naming (mixed abbreviations, unclear class intent, random folder layouts) makes services harder to navigate. This slows modernization and increases accidental coupling.

## Solution

Adopt explicit conventions for project names, namespaces, class/member names, and folder structure. Prefer feature-oriented organization over technical dumping grounds.

## Benefits

- Faster navigation and onboarding
- Better readability in PRs
- Lower risk during large refactors

## Tradeoffs

- Requires enforcement in review and tooling
- Some legacy names will need staged migration

## When to Use

- All new projects and modernization changes
- Any service undergoing folder/namespace cleanup

## When NOT to Use

- Emergency production patches where renaming would increase risk

## Implementation Steps

1. Adopt shared naming standards for projects, namespaces, and types.
2. Normalize folder layout (prefer feature slices over giant shared folders).
3. Remove ambiguous abbreviations in new/changed code.
4. Align API route/resource names with domain language.
5. Add analyzer/style rule enforcement where practical.

## Code Example

See [`examples/`](./examples/):
- `Before_Naming.cs` - ambiguous naming and mixed concerns.
- `After_Naming.cs` - explicit names and feature-oriented structure.

## Validation Checklist

See [`CHECKLIST.md`](./CHECKLIST.md).

## References

- https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/coding-conventions
- https://learn.microsoft.com/dotnet/standard/design-guidelines/
