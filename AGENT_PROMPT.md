# Apply Library Consolidation to OgeFieldOps.Web

## Context

You are on branch: `feature/library-consolidation`

Five shared library projects have been created in the `lib/` folder:
- OgeFieldOps.Core.Observability
- OgeFieldOps.Core.Infrastructure
- OgeFieldOps.Core.Messaging
- OgeFieldOps.Core.Storage
- OgeFieldOps.Core.Data

## Your Task

Execute the library consolidation workflow to update `legacy-upload-demo-modernized/OgeFieldOps.Web` to use these libraries.

### Step 1: Build All Libraries (Release mode)

For each library in `lib/`, run:
```bash
cd lib/OgeFieldOps.Core.Observability && dotnet build -c Release
cd ../OgeFieldOps.Core.Infrastructure && dotnet build -c Release
cd ../OgeFieldOps.Core.Messaging && dotnet build -c Release
cd ../OgeFieldOps.Core.Storage && dotnet build -c Release
cd ../OgeFieldOps.Core.Data && dotnet build -c Release
```

Verify all builds succeed with no errors.

### Step 2: Pack Libraries to NuGet

For each library, pack to `lib/local-nuget/`:
```bash
cd lib/OgeFieldOps.Core.Observability && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Infrastructure && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Messaging && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Storage && dotnet pack -c Release -o ../local-nuget
cd ../OgeFieldOps.Core.Data && dotnet pack -c Release -o ../local-nuget
```

Verify `.nupkg` files exist in `lib/local-nuget/`:
- OgeFieldOps.Core.Observability.1.0.0.nupkg
- OgeFieldOps.Core.Infrastructure.1.0.0.nupkg
- OgeFieldOps.Core.Messaging.1.0.0.nupkg
- OgeFieldOps.Core.Storage.1.0.0.nupkg
- OgeFieldOps.Core.Data.1.0.0.nupkg

### Step 3: Create NuGet.config in App

Create: `legacy-upload-demo-modernized/OgeFieldOps.Web/NuGet.config`

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

Add these PackageReferences to the `<ItemGroup>` in `legacy-upload-demo-modernized/OgeFieldOps.Web/OgeFieldOps.Web.csproj`:

```xml
<PackageReference Include="OgeFieldOps.Core.Observability" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Infrastructure" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Messaging" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Storage" Version="1.0.0" />
<PackageReference Include="OgeFieldOps.Core.Data" Version="1.0.0" />
```

### Step 5: Update Program.cs

File: `legacy-upload-demo-modernized/OgeFieldOps.Web/Program.cs`

**Replace using statements** (lines 1-12):
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

**Update middleware registration** (around line 127):
```csharp
// OLD:
app.UseMiddleware<CorrelationIdMiddleware>();

// NEW:
app.UseMiddleware<OgeFieldOps.Core.Observability.CorrelationIdMiddleware>();
```

**Update health check registration** (around lines 88-90):
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

**Update service registrations** (around lines 77-80):
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

File: `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/OutageWorkflowService.cs`

**Add using statements:**
```csharp
using OgeFieldOps.Core.Messaging;
using OgeFieldOps.Core.Storage;
```

**Update constructor to use library interfaces:**
- Change `INotificationService` → `IEventPublisher` (from OgeFieldOps.Core.Messaging)
- Update any references to these interfaces in method bodies

### Step 7: Delete Custom Implementation Files

Remove these files from the app (they're now in libraries):
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Middleware/CorrelationIdMiddleware.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/NotificationService.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Services/FileStorageService.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Data/SqlConnectionFactory.cs`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Infrastructure/HealthChecks.cs`

Remove empty folders if any are left:
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Middleware/`
- `legacy-upload-demo-modernized/OgeFieldOps.Web/Infrastructure/`

### Step 8: Restore and Build

```bash
cd legacy-upload-demo-modernized/OgeFieldOps.Web
dotnet restore
dotnet build
```

Verify:
- ✅ No compilation errors
- ✅ No warnings about missing types
- ✅ All library references resolved
- ✅ Build succeeds

### Step 9: Summary Report

Output:
1. List of files deleted/removed
2. List of files modified with brief before/after
3. Build output showing success
4. Verification that all 5 library packages are referenced
5. Confirmation that app still has same functionality (code organization only changed)

## Success Criteria

- ✅ All 5 libraries built successfully
- ✅ All 5 libraries packed to .nupkg in local-nuget/
- ✅ NuGet.config created
- ✅ App .csproj updated with 5 PackageReferences
- ✅ Program.cs updated with library type registrations
- ✅ OutageWorkflowService updated to use library interfaces
- ✅ 5 custom code files deleted from app
- ✅ App builds without errors or warnings
- ✅ No references to old custom types remain
- ✅ Behavior unchanged (only organization improved)

## Notes

- Work on branch: `feature/library-consolidation`
- If anything fails, we can revert with: `git checkout main`
- This is a proof-of-concept for instruction-driven library consolidation
- App functionality should be identical after this change
