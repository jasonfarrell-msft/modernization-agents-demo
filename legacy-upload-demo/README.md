# Legacy Demo Apps — modernization baseline

This folder contains the **"before"** state for the modernization demo: an authentic,
pre-cloud-era .NET Framework 4.8 line-of-business web application that two different
AI modernization approaches will later transform, and that Playwright tests will later
validate (Playwright work happens in the modernization workshop, not here).

## OgeFieldOps.Web — primary legacy app

**OGE Field Operations & Outage Portal** — a server-rendered intranet app for a power
company's field operations / dispatch team, built the way it would have been when
.NET Framework 4.8 was the standard.

### Stack (period-accurate)
- **ASP.NET MVC 5** (System.Web.Mvc 5.2.9) + Razor v3, `System.Web` request pipeline.
- `packages.config` NuGet (non-SDK project), `Web.config`, `Global.asax`.
- **Bootstrap 3** + **jQuery 3.4** + unobtrusive validation, `System.Web.Optimization` bundling.
- **Combined frontend + backend in ONE project** — no SPA, no React, no Web API split.
- **Raw ADO.NET** (`SqlConnection` / `SqlCommand` / `SqlDataReader` / `SqlDataAdapter`),
  no ORM, against on-prem **SQL Server Express**.

### Features (each maps to a classic pre-cloud pattern)
| Feature | Pattern demonstrated |
|---|---|
| **Forms Authentication** (login/logout, roles) | `<authentication mode="Forms">`, SQL-backed users, salted SHA-256 |
| **File upload** of field docs / meter files | Saved to a **config-defined server directory** (`appSettings["UploadDirectory"]`) + DB row |
| **Outage work-order list** (search + server-side paging) | `SqlDataReader` rendered in a Razor table |
| **CSV export** of outages | `SqlDataAdapter` → `DataTable` → streamed `FileResult` |
| **Dispatch email notifications** | `System.Net.Mail` **SMTP pickup directory** → `.eml` files (admin "Notifications" page) |
| **Audit log** | Appends to a **config-defined text file** (`appSettings["AuditLogPath"]`) |

### Intentionally "dirty" (the modernization targets)
- Connection string **and secrets in `Web.config` plaintext** (API key, service password).
- On-prem SQL Server via ADO.NET; synchronous IO; no DI container; static helpers.
- Server-local file/SMTP/log paths (pre-cloud, machine-bound).
- `customErrors` off, request validation mode 2.0, `runAllManagedModulesForAllRequests`.

> Modernization should: move secrets to **Azure Key Vault** + **Managed Identity**, replace
> server-local paths with **Blob Storage**, replace SMTP pickup with a mail/queue service,
> and containerize / move to modern ASP.NET Core — while preserving behavior.

### Demo accounts
| Username | Password | Role |
|---|---|---|
| `admin` | `Admin@2014` | Admin |
| `dispatcher` | `Dispatch@2014` | Dispatcher |
| `ftech` | `Field@2014` | FieldTech |

### Project layout
```
OgeFieldOps.Web/
  App_Start/        RouteConfig, FilterConfig, BundleConfig
  Controllers/      Account, Home, Outages, Admin
  Data/             Database (ADO.NET), OutageRepository, UserRepository
  Models/           OutageModels, AccountViewModels
  Services/         FileStorageService, EmailService, AuditLogService
  Views/            Razor views (Bootstrap 3)
  Database/         Schema.sql, Seed.sql
  Content/ Scripts/ Vendored Bootstrap 3 / jQuery (period-accurate, committed)
  Web.config        Deliberately legacy configuration
```

## Build & deploy

The app is a classic `System.Web` web project and **cannot** be built with `dotnet` CLI —
it needs MSBuild + the web publishing targets. CI does this for you:

- `.github/workflows/deploy-legacy-web.yml`
  - **build** job on GitHub-hosted `windows-latest`: `nuget restore` → `msbuild` FileSystem
    publish → upload artifact.
  - **deploy** job on the **self-hosted** runner (the VM): downloads the artifact and runs
    `scripts/deploy-iis.ps1` to deploy into IIS as a **classic ASP.NET 4.x** site
    (app pool CLR **v4.0**, Integrated).

Database provisioning (SQL Server Express on the VM, `OgeFieldOps` DB, `oge_app` login,
`Schema.sql` + `Seed.sql`) is described in the repo provisioning notes/scripts.

## LegacyUploadDemo — supporting console utility

A small **net48 console** app (`SqlConnection`/`SqlCommand`, config-defined upload dir) kept
as an additional minimal legacy artifact. The web app above is the primary modernization target.
