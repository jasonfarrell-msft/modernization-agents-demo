using System.ComponentModel;
using ModelContextProtocol.Protocol;
using ModelContextProtocol.Server;
using PatternsMcp.Server.Services;

namespace PatternsMcp.Server.Resources;

[McpServerResourceType]
public sealed class PatternResources(PatternRepository repository)
{
    [McpServerResource(
        UriTemplate = "pattern://{category}/readme",
        Name = "Pattern README",
        MimeType = "text/markdown")]
    [Description("Full README.md for a pattern category.")]
    public TextResourceContents GetReadme(string category) =>
        new()
        {
            Uri = $"pattern://{category}/readme",
            MimeType = "text/markdown",
            Text = repository.GetPatternReadme(category),
        };

    [McpServerResource(
        UriTemplate = "pattern://{category}/checklist",
        Name = "Pattern Checklist",
        MimeType = "text/markdown")]
    [Description("Validation checklist (raw markdown) for a pattern category.")]
    public TextResourceContents GetChecklist(string category)
    {
        // The repository parses the checklist; for resource access we serve the raw markdown.
        var path = Path.Combine(repository.RootPath, category, "CHECKLIST.md");
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"CHECKLIST.md not found for pattern '{category}'.");
        }

        return new TextResourceContents
        {
            Uri = $"pattern://{category}/checklist",
            MimeType = "text/markdown",
            Text = File.ReadAllText(path),
        };
    }

    [McpServerResource(
        UriTemplate = "pattern://{category}/examples/{fileName}",
        Name = "Pattern Example",
        MimeType = "text/plain")]
    [Description("A single example file under a pattern's examples folder.")]
    public TextResourceContents GetExample(string category, string fileName) =>
        new()
        {
            Uri = $"pattern://{category}/examples/{fileName}",
            MimeType = GuessMimeType(fileName),
            Text = repository.GetExampleContents(category, fileName),
        };

    private static string GuessMimeType(string fileName) =>
        Path.GetExtension(fileName).ToLowerInvariant() switch
        {
            ".cs" => "text/x-csharp",
            ".bicep" => "text/plain",
            ".json" => "application/json",
            ".md" => "text/markdown",
            ".yaml" or ".yml" => "application/yaml",
            _ => "text/plain",
        };
}
