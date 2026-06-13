using System.ComponentModel;
using ModelContextProtocol.Server;
using PatternsMcp.Server.Services;

namespace PatternsMcp.Server.Tools;

[McpServerToolType]
public sealed class PatternTools(PatternRepository repository)
{
    [McpServerTool(Name = "list_patterns", ReadOnly = true, Idempotent = true)]
    [Description("Lists every available pattern category in the dotnet-patterns repository (e.g. clean-architecture, dependency-injection, managed-identity).")]
    public IReadOnlyList<PatternSummary> ListPatterns() =>
        repository.ListPatterns();

    [McpServerTool(Name = "get_pattern", ReadOnly = true, Idempotent = true)]
    [Description("Returns the full README.md markdown for a pattern category.")]
    public string GetPattern(
        [Description("Pattern category slug, e.g. 'managed-identity'. Use list_patterns to discover valid values.")] string category) =>
        repository.GetPatternReadme(category);

    [McpServerTool(Name = "get_checklist", ReadOnly = true, Idempotent = true)]
    [Description("Returns the validation checklist for a pattern, parsed into structured sections and items.")]
    public IReadOnlyList<ChecklistSection> GetChecklist(
        [Description("Pattern category slug.")] string category) =>
        repository.GetChecklist(category);

    [McpServerTool(Name = "get_examples", ReadOnly = true, Idempotent = true)]
    [Description("Lists example files for a pattern. Set include_contents=true to also return the file bodies.")]
    public IReadOnlyList<ExampleFile> GetExamples(
        [Description("Pattern category slug.")] string category,
        [Description("Include the full text of each example file.")] bool includeContents = false) =>
        repository.ListExamples(category, includeContents);

    [McpServerTool(Name = "get_example_file", ReadOnly = true, Idempotent = true)]
    [Description("Returns the full text of a specific example file within a pattern category.")]
    public string GetExampleFile(
        [Description("Pattern category slug.")] string category,
        [Description("File name within the category's examples folder, e.g. 'Program.cs'.")] string fileName) =>
        repository.GetExampleContents(category, fileName);

    [McpServerTool(Name = "search_patterns", ReadOnly = true, Idempotent = true)]
    [Description("Case-insensitive substring search across all pattern READMEs, checklists and example files. Returns ranked file/line snippets.")]
    public IReadOnlyList<SearchHit> SearchPatterns(
        [Description("Search term. Required.")] string query,
        [Description("Optional pattern category to restrict the search to.")] string? category = null,
        [Description("Maximum number of hits to return.")] int maxResults = 25) =>
        repository.Search(query, category, Math.Clamp(maxResults, 1, 200));

    [McpServerTool(Name = "get_adoption_matrix", ReadOnly = true, Idempotent = true)]
    [Description("Returns the parsed pattern adoption matrix from the root README, mapping services to per-pattern adoption status.")]
    public AdoptionMatrix? GetAdoptionMatrix() =>
        repository.GetAdoptionMatrix();

    [McpServerTool(Name = "recommend_patterns", ReadOnly = true, Idempotent = true)]
    [Description("Heuristically recommends pattern categories that apply to a code snippet (detects sync-over-async, embedded credentials, service locator usage, oversized constructors, etc.).")]
    public IReadOnlyList<Recommendation> RecommendPatterns(
        [Description("File contents or code snippet to analyse.")] string fileContent,
        [Description("Optional language hint, e.g. 'csharp'.")] string? language = null) =>
        repository.Recommend(fileContent, language);
}
