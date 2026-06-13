using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ModelContextProtocol.Server;
using PatternsMcp.Server.Services;

var builder = Host.CreateApplicationBuilder(args);

// CRITICAL for STDIO: stdout is the JSON-RPC channel. Send all logs to stderr.
builder.Logging.AddConsole(o => o.LogToStandardErrorThreshold = LogLevel.Trace);

// Resolve PATTERNS_PATH:
//   1. PATTERNS_PATH env var (preferred — decouples server from repo location).
//   2. First CLI arg.
//   3. Sibling 'dotnet-patterns' directory walked up from cwd (dev fallback).
var patternsPath =
    Environment.GetEnvironmentVariable("PATTERNS_PATH")
    ?? args.FirstOrDefault()
    ?? FindDefaultPatternsPath();

builder.Services.AddSingleton(new PatternRepository(patternsPath));

builder.Services
    .AddMcpServer(options =>
    {
        options.ServerInfo = new()
        {
            Name = "dotnet-patterns",
            Version = "0.1.0",
            Title = ".NET Patterns Knowledge Server",
        };
    })
    .WithStdioServerTransport()
    .WithToolsFromAssembly()
    .WithResourcesFromAssembly();

await builder.Build().RunAsync();

static string FindDefaultPatternsPath()
{
    var dir = new DirectoryInfo(Directory.GetCurrentDirectory());
    while (dir is not null)
    {
        var candidate = Path.Combine(dir.FullName, "dotnet-patterns");
        if (Directory.Exists(candidate))
        {
            return candidate;
        }

        dir = dir.Parent;
    }

    throw new InvalidOperationException(
        "Could not locate a dotnet-patterns directory. Set the PATTERNS_PATH environment variable.");
}
