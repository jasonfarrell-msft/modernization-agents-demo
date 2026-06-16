# Naming Conventions & Code Organization — Validation Checklist

## Projects and namespaces

- [ ] Project names follow consistent solution naming (for example, `Company.Product.Service`)
- [ ] Namespaces match folder structure and project intent
- [ ] Test projects follow `{ProjectName}.Tests` convention

## Types and members

- [ ] Class names are nouns and describe one responsibility
- [ ] Interface names use `I` prefix and describe capability
- [ ] Method names are verbs and intention-revealing
- [ ] Boolean members use `Is/Has/Can` prefixes
- [ ] Abbreviations are avoided unless domain-standard and well-known

## File and folder organization

- [ ] File name matches primary type
- [ ] Folders are organized by feature or bounded context, not catch-all "Helpers"
- [ ] Shared abstractions are minimal and purposeful

## API and contracts

- [ ] Route/resource names are domain terms and pluralized consistently
- [ ] DTO names clearly distinguish requests, responses, and events

## Maintainability

- [ ] New names are consistent with existing domain vocabulary
- [ ] Renames include dependent test updates
- [ ] No misleading legacy names introduced in new code
