# Library Consolidation Demo - Setup & Next Steps

## ✅ Setup Complete

### Branch Status

- **Branch Created**: `feature/library-consolidation`
- **Libraries Committed**: All 5 projects with full source code
- **Safety**: `main` branch is untouched - safe to experiment
- **Revert Path**: `git checkout main` to undo at any time

### What's Ready

#### 1. Five Library Projects (in `lib/`)

Complete with `.csproj` files and source code:

- **OgeFieldOps.Core.Observability**
  - `CorrelationIdMiddleware.cs` — X-Correlation-ID header propagation
  - Shared observability patterns

- **OgeFieldOps.Core.Infrastructure**
  - `HealthChecks.cs` — BlobStorageHealthCheck, SqlHealthCheck
  - Infrastructure patterns

- **OgeFieldOps.Core.Messaging**
  - `IEventPublisher.cs` — Interface + event records
  - `ServiceBusEventPublisher.cs` — Azure Service Bus implementation
  - Shared messaging patterns

- **OgeFieldOps.Core.Storage**
  - `IFileStorageService.cs` — Interface + records
  - `BlobFileStorageService.cs` — Azure Blob Storage implementation
  - Shared file storage patterns

- **OgeFieldOps.Core.Data**
  - `ManagedIdentitySqlConnectionFactory.cs` — Entra auth SQL connections
  - Shared data access patterns

#### 2. Agent Instructions

**File**: `AGENT_PROMPT.md` (repository root)

- 9-step workflow
- Build → Package → Update App → Verify
- Clear success criteria
- Revert instructions

#### 3. Supporting Documentation

- `lib/LIBRARY_REPLACEMENT_INSTRUCTIONS.md` — Detailed instruction set
- `lib/CODE_REFERENCE.md` — Source code reference material
- `lib/README.md` — Overview of library structure

---

## Agent's Workflow (9 Steps)

### Step 1: Build All Libraries (Release mode)

```bash
cd lib/OgeFieldOps.Core.Observability && dotnet build -c Release
cd ../OgeFieldOps.Core.Infrastructure && dotnet build -c Release
cd ../OgeFieldOps.Core.Messaging && dotnet build -c Release
cd ../OgeFieldOps.Core.Storage && dotnet build -c Release
cd ../OgeFieldOps.Core.Data && dotnet build -c Release
```

**Verification**: All builds succeed with no errors

### Step 2: Pack Libraries to NuGet

```bash
cd lib/OgeFieldOps.Core.Observability && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Infrastructure && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Messaging && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Storage && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Data && dotnet pack -c Release -o ../local-nuget
```

**Verification**: `.nupkg` files exist in `lib/local-nuget/`:
- OgeFieldOps.Core.Observability.1.0.0.nupkg
- OgeFieldOps.Core.Infrastructure.1.0.0.nupkg
- OgeFieldOps.Core.Messaging.1.0.0.nupkg
- OgeFieldOps.Core.Storage.1.0.0.nupkg
- OgeFieldOps.Core.Data.1.0.0.nupkg

### Step 3: Create NuGet.config in App

**File**: `legacy-upload-demo-modernized/OgeFieldOps.Web/NuGet.config` (create new)

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="local" value="../../lib/local-nuget" />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
</configuration>
```

### Step 4: Update OgeFieldOps.Web.csproj

**File**: `legacy-upload-demo-modernized/OgeFieldOps.Web/OgeFieldOps.Web.csproj`

Add these PackageReferences to the `<ItemGroup>`:

```xml
<PackageReference Include="OgeFieldOps.Core.Observability" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Infrastructure" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Messaging" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Storage" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Data" Version="1.0.0" />
```

### Step 5: Update Program.cs

**File**: `legacy-upload-demo-modernized/OgeFieldOps.Web/Program.cs`

#### 5a: Replace Using Statements (lines 1-12)

```csharp
using OgeFieldOps.Core.Observability;
using OgeFieldOps.Core.Infrastructure;
using OgeFieldOps.Core.Messaging;
using OgeFieldOps.Core.Storage;
using OgeFieldOps.Core.Data;
using OgeFieldOps.Web.Configuration;
using OgeFieldOps.Web.Data;
using OgeFieldOps.Web.Infrastructure;
using OgeFieldOps.Web.Middleware;
using OgeFieldOps.Web.Services;
using OpenTelemetry.Logs;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
```

#### 5b: Update Middleware Registration (around line 127)

```csharp
// OLD:
app.UseMiddleware<CorrelationIdMiddleware>();

// NEW:
app.UseMiddleware<OgeFieldOps.Core.Observability.CorrelationIdMiddleware>();
```

#### 5c: Update Health Check Registration (around lines 88-90)

```csharp
// OLD:
builder.Services.AddHealthChecks()
    .AddCheck<BlobStorageHealthCheck>("blob-storage")
    .AddCheck<SqlHealthCheck>("sql");

// NEW:
builder.Services.AddHealthChecks()
    .AddCheck<OgeFieldOps.Core.Infrastructure.BlobStorageHealthCheck>("blob-storage")
    .AddCheck<OgeFieldOps.Core.Infrastructure.SqlHealthCheck>("sql");
```

#### 5d: Update Service Registrations (around lines 77-80)

```csharp
// OLD:
builder.Services.AddScoped<IFileStorageService, BlobFileStorageService>();
builder.Services.AddScoped<INotificationService, ServiceBusNotificationService>();
builder.Services.AddScoped<IOutageRepository, OutageRepository>();
builder.Services.AddSingleton<ITicketNumberGenerator, TicketNumberGenerator>();
builder.Services.AddScoped<OutageWorkflowService>();
builder.Services.AddSingleton<ISqlConnectionFactory, ManagedIdentitySqlConnectionFactory>();

// NEW:
builder.Services.AddScoped<OgeFieldOps.Core.Storage.IFileStorageService, OgeFieldOps.Core.Storage.BlobFileStorageService>();
builder.Services.AddScoped<OgeFieldOps.Core.Messaging.IEventPublisher, OgeFieldOps.Core.Messaging.ServiceBusEventPublisher>();
builder.Services.AddScoped<IOutageRepository, OutageRepository>();
builder.Services.AddSingleton<ITicketNumberGenerator, TicketNumberGenerator>();
builder.Services.AddScoped<OutageWorkflowService>();
builder.Services.AddSingleton<OgeFieldOps.Core.Data.ISqlConnectionFactory, OgeFieldOps.Core.Data.ManagedIdentitySqlConnectionFactory>();
```

### Step 6: Update OutageWorkflowService.cs

**File**: `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/OutageWorkflowService.cs`

#### 6a: Add Using Statements

```csharp
using OgeFieldOps.Core.Messaging;
using OgeFieldOps.Core.Storage;
```

#### 6b: Update Constructor

Change interface types:
- `INotificationService` → `IEventPublisher` (from OgeFieldOps.Core.Messaging)
- Update any method references to use new interface names

### Step 7: Delete Custom Implementation Files

Remove these files from the app (now in libraries):

- `legacy-upload-demo-modernized/OgeFieldOps.Web/Middleware/CorrelationIdMiddleware.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/NotificationService.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/FileStorageService.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Data/SqlConnectionFactory.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Infrastructure/HealthChecks.cs`

**Remove Empty Folders:**
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Middleware/` (if empty)
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Infrastructure/` (if empty)

### Step 8: Restore and Build

```bash
cd legacy-upload-demo-modernized/OgeFieldOps.Web
dotnet restore
dotnet build
```

**Verification:**
- ✅ No compilation errors
- ✅ No warnings about missing types
- ✅ All library references resolved
- ✅ Build succeeds

### Step 9: Summary Report

Output:
1. List of files deleted/removed
2. List of files modified with brief before/after summary
3. Build output showing success
4. Verification that all 5 library packages are referenced
5. Confirmation that app functionality unchanged (code organization only)

---

## Expected Result After Agent Completes

### Package Structure

```
lib/local-nuget/
├── OgeFieldOps.Core.Observability.1.0.0.nupkg
├── OgeFieldOps.Core.Infrastructure.1.0.0.nupkg
├── OgeFieldOps.Core.Messaging.1.0.0.nupkg
├── OgeFieldOps.Core.Storage.1.0.0.nupkg
└── OgeFieldOps.Core.Data.1.0.0.nupkg
```

### App Structure

```
legacy-upload-demo-modernized/OgeFieldOps.Web/
├── NuGet.config (NEW)
├── OgeFieldOps.Web.csproj (UPDATED - added 5 PackageReferences)
├── Program.cs (UPDATED - library type registrations)
├── Configuration/
│   └── AppOptions.cs
├── Controllers/
│   ├── HomeController.cs
│   └── OutagesController.cs
├── Data/
│   ├── OutageRepository.cs (unchanged - domain logic)
│   └── SqlConnectionFactory.cs (DELETED)
├── Infrastructure/
│   └── (folder empty or removed - HealthChecks.cs DELETED)
├── Middleware/
│   └── (folder empty or removed - CorrelationIdMiddleware.cs DELETED)
├── Models/
│   └── OutageModels.cs
├── Services/
│   ├── OutageWorkflowService.cs (UPDATED - uses library interfaces)
│   ├── NotificationService.cs (DELETED)
│   └── FileStorageService.cs (DELETED)
└── Views/
    └── [...]
```

---

## Success Criteria Checklist

- ✅ All 5 libraries built successfully (Release mode)
- ✅ All 5 libraries packed to .nupkg in lib/local-nuget/
- ✅ NuGet.config created pointing to local-nuget/
- ✅ App .csproj updated with 5 PackageReferences
- ✅ Program.cs updated with all library type registrations
- ✅ OutageWorkflowService.cs updated to use library interfaces
- ✅ 5 custom code files deleted from app
- ✅ Empty folders removed (Middleware/, Infrastructure/)
- ✅ App builds without errors
- ✅ App builds without warnings about missing types
- ✅ No references to old custom types remain in code
- ✅ Behavior unchanged (only organization improved)

---

## How to Send to Agent

### Agent Selection
Use a `.NET modernization agent` or `.NET-capable general-purpose agent`:
- C# Expert
- Software Engineer Agent
- .NET Upgrade
- General-purpose agent

### Prompt Template

```
Execute the library consolidation workflow to consolidate custom implementations 
into reusable shared libraries.

You are on branch: feature/library-consolidation

Files to reference:
- AGENT_PROMPT.md (this directory) — Main instructions
- lib/LIBRARY_REPLACEMENT_INSTRUCTIONS.md — Detailed specs
- lib/CODE_REFERENCE.md — Source code reference

Execute the 9-step workflow:
1. Build all 5 libraries (Release mode)
2. Pack libraries to lib/local-nuget/
3. Create NuGet.config in app folder
4. Update app .csproj with library PackageReferences
5. Update Program.cs with library type registrations
6. Update OutageWorkflowService.cs to use library interfaces
7. Delete 5 custom implementation files from app
8. Restore packages and build (verify no errors)
9. Provide comprehensive summary report

Output:
- Files created/modified/deleted with before/after diffs
- Build output verifying success
- Success criteria checklist completion
- Any issues or blockers encountered

Key Constraint: All work happens on feature/library-consolidation branch.
If anything fails, we can revert with: git checkout main
```

---

## After Agent Completes

### Review Changes

1. Open VS Code and review changes
2. Check that all 5 custom files are deleted
3. Verify NuGet.config exists
4. Verify Program.cs updated correctly
5. Check lib/local-nuget/ for .nupkg files

### Test (Optional)

```bash
cd legacy-upload-demo-modernized/OgeFieldOps.Web
dotnet restore
dotnet build
dotnet run
```

### Commit Changes

```bash
git add .
git commit -m "Apply library consolidation: extract custom implementations into 5 reusable libraries

- Build all 5 libraries (Observability, Infrastructure, Messaging, Storage, Data)
- Pack to NuGet packages in lib/local-nuget/
- Create NuGet.config pointing to local packages
- Update OgeFieldOps.Web to reference libraries via PackageReferences
- Update Program.cs with library type registrations
- Update OutageWorkflowService to use library interfaces
- Delete 5 custom implementation files from app
- Verify compilation succeeds

App functionality unchanged; only code organization improved.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Create PR (Optional)

Create a pull request comparing `feature/library-consolidation` to `main` to see all changes:

```bash
git push origin feature/library-consolidation
# Then create PR via GitHub UI
```

---

## Safety & Revert Options

### If Something Goes Wrong

```bash
# Go back to main (undoes all changes on this branch)
git checkout main

# Later, return to the branch
git checkout feature/library-consolidation
```

### Hard Reset (if you want to start over on this branch)

```bash
# Reset branch to main state (keeps branch, resets changes)
git reset --hard main
```

### Delete Branch Entirely

```bash
# Delete the branch (if you don't want it anymore)
git branch -D feature/library-consolidation
```

---

## Key Points

- **Safe Branching**: `main` is completely untouched
- **Instruction-Driven**: Agent follows explicit 9-step workflow
- **Library-First**: Libraries already exist; agent builds & packages them
- **Zero Breaking Changes**: App behavior identical before/after
- **Demonstration**: This proves instruction-driven consolidation works
- **Replicable**: Same process can be applied to other apps

---

## Summary

You have successfully:

1. ✅ Created 5 library projects with source code
2. ✅ Created a safe branch (`feature/library-consolidation`)
3. ✅ Committed libraries to the branch
4. ✅ Created detailed agent instructions (AGENT_PROMPT.md)
5. ✅ Prepared supporting documentation

**Next Step**: Send `AGENT_PROMPT.md` to a modernization agent to execute the consolidation workflow.

**Expected Outcome**: App uses libraries instead of maintaining custom implementations. All 5 custom code files removed. Build succeeds. Code organization improved.
