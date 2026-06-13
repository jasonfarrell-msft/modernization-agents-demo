using System.Text.RegularExpressions;

namespace PatternsMcp.Server.Services;

/// <summary>
/// Read-only access to the on-disk dotnet-patterns repository.
/// All paths are resolved against <see cref="RootPath"/>; traversal outside the root is rejected.
/// </summary>
public sealed partial class PatternRepository
{
    private readonly string _rootPath;

    public PatternRepository(string rootPath)
    {
        if (!Directory.Exists(rootPath))
        {
            throw new DirectoryNotFoundException(
                $"Patterns root not found: '{rootPath}'. " +
                $"Set the PATTERNS_PATH environment variable to the dotnet-patterns directory.");
        }

        _rootPath = Path.GetFullPath(rootPath);
    }

    public string RootPath => _rootPath;

    /// <summary>Lists every category that has a README.md under the patterns root.</summary>
    public IReadOnlyList<PatternSummary> ListPatterns()
    {
        var results = new List<PatternSummary>();

        foreach (var dir in Directory.EnumerateDirectories(_rootPath).OrderBy(d => d))
        {
            var category = Path.GetFileName(dir);
            var readmePath = Path.Combine(dir, "README.md");
            if (!File.Exists(readmePath))
            {
                continue;
            }

            var checklistExists = File.Exists(Path.Combine(dir, "CHECKLIST.md"));
            var examplesDir = Path.Combine(dir, "examples");
            var exampleCount = Directory.Exists(examplesDir)
                ? Directory.GetFiles(examplesDir).Length
                : 0;

            var title = ExtractTitle(readmePath) ?? category;

            results.Add(new PatternSummary(
                Category: category,
                Title: title,
                HasChecklist: checklistExists,
                ExampleCount: exampleCount));
        }

        return results;
    }

    /// <summary>Returns the full README.md for a category.</summary>
    public string GetPatternReadme(string category)
    {
        var path = ResolveCategoryFile(category, "README.md");
        return File.ReadAllText(path);
    }

    /// <summary>Returns the parsed checklist items grouped by section.</summary>
    public IReadOnlyList<ChecklistSection> GetChecklist(string category)
    {
        var path = ResolveCategoryFile(category, "CHECKLIST.md");
        var sections = new List<ChecklistSection>();
        ChecklistSection? current = null;

        foreach (var rawLine in File.ReadAllLines(path))
        {
            var line = rawLine.TrimEnd();

            if (line.StartsWith("## ", StringComparison.Ordinal))
            {
                current = new ChecklistSection(line[3..].Trim(), []);
                sections.Add(current);
                continue;
            }

            var match = ChecklistItemRegex().Match(line);
            if (match.Success && current is not null)
            {
                current.Items.Add(new ChecklistItem(
                    Done: match.Groups[1].Value == "x",
                    Text: match.Groups[2].Value.Trim()));
            }
        }

        return sections;
    }

    /// <summary>Lists files in the category's examples directory.</summary>
    public IReadOnlyList<ExampleFile> ListExamples(string category, bool includeContents)
    {
        var dir = Path.Combine(GetCategoryDirectory(category), "examples");
        if (!Directory.Exists(dir))
        {
            return [];
        }

        return [.. Directory.EnumerateFiles(dir)
            .OrderBy(p => p)
            .Select(p => new ExampleFile(
                FileName: Path.GetFileName(p),
                RelativePath: Path.GetRelativePath(_rootPath, p),
                Contents: includeContents ? File.ReadAllText(p) : null))];
    }

    /// <summary>Returns the contents of a specific example file.</summary>
    public string GetExampleContents(string category, string fileName)
    {
        var path = Path.Combine(GetCategoryDirectory(category), "examples", fileName);
        EnsureWithinRoot(path);
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"Example not found: {category}/examples/{fileName}");
        }

        return File.ReadAllText(path);
    }

    /// <summary>Substring search across READMEs, CHECKLISTs and examples.</summary>
    public IReadOnlyList<SearchHit> Search(string query, string? category, int maxResults)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return [];
        }

        var hits = new List<SearchHit>();
        var categories = category is null
            ? ListPatterns().Select(p => p.Category)
            : [category];

        foreach (var cat in categories)
        {
            var dir = GetCategoryDirectory(cat);
            foreach (var file in EnumerateSearchableFiles(dir))
            {
                var lines = File.ReadAllLines(file);
                for (var i = 0; i < lines.Length; i++)
                {
                    if (lines[i].Contains(query, StringComparison.OrdinalIgnoreCase))
                    {
                        hits.Add(new SearchHit(
                            Category: cat,
                            RelativePath: Path.GetRelativePath(_rootPath, file),
                            LineNumber: i + 1,
                            Snippet: lines[i].Trim()));

                        if (hits.Count >= maxResults)
                        {
                            return hits;
                        }
                    }
                }
            }
        }

        return hits;
    }

    /// <summary>Parses the adoption matrix table from the root README.</summary>
    public AdoptionMatrix? GetAdoptionMatrix()
    {
        var rootReadme = Path.Combine(_rootPath, "README.md");
        if (!File.Exists(rootReadme))
        {
            return null;
        }

        var lines = File.ReadAllLines(rootReadme);
        var tableStart = -1;
        for (var i = 0; i < lines.Length; i++)
        {
            if (lines[i].StartsWith("| Service ", StringComparison.OrdinalIgnoreCase))
            {
                tableStart = i;
                break;
            }
        }

        if (tableStart < 0)
        {
            return null;
        }

        var headers = SplitRow(lines[tableStart]);
        var rows = new List<AdoptionRow>();

        // Skip the separator row.
        for (var i = tableStart + 2; i < lines.Length; i++)
        {
            if (!lines[i].StartsWith('|'))
            {
                break;
            }

            var cells = SplitRow(lines[i]);
            if (cells.Length != headers.Length)
            {
                continue;
            }

            var statuses = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            for (var c = 1; c < headers.Length; c++)
            {
                statuses[headers[c]] = cells[c];
            }

            rows.Add(new AdoptionRow(Service: cells[0], Statuses: statuses));
        }

        return new AdoptionMatrix(Headers: headers, Rows: rows);
    }

    /// <summary>Heuristic match of pattern categories to a code snippet.</summary>
    public IReadOnlyList<Recommendation> Recommend(string fileContent, string? language)
    {
        var matches = new List<Recommendation>();
        var content = fileContent ?? string.Empty;

        // Async patterns — sync-over-async or missing CancellationToken.
        if (Regex.IsMatch(content, @"\.Result\b|\.Wait\(\)|\.GetAwaiter\(\)\.GetResult\(\)"))
        {
            matches.Add(new Recommendation(
                Category: "async-patterns",
                Reason: "Detected sync-over-async (`.Result` / `.Wait()` / `.GetAwaiter().GetResult()`). Adopt async-all-the-way.",
                Confidence: 0.95));
        }

        if (Regex.IsMatch(content, @"\bpublic\s+async\s+Task\b") &&
            !content.Contains("CancellationToken", StringComparison.Ordinal))
        {
            matches.Add(new Recommendation(
                Category: "async-patterns",
                Reason: "Async method without a CancellationToken parameter.",
                Confidence: 0.7));
        }

        // DI — manual `new` of services or static service locator.
        if (Regex.IsMatch(content, @"\bnew\s+SqlConnection\b|\bnew\s+HttpClient\(\)"))
        {
            matches.Add(new Recommendation(
                Category: "dependency-injection",
                Reason: "Direct instantiation of `SqlConnection` / `HttpClient`. Use DI + `IHttpClientFactory`.",
                Confidence: 0.9));
        }

        if (content.Contains("ServiceLocator", StringComparison.Ordinal) ||
            Regex.IsMatch(content, @"IServiceProvider\.\s*GetService"))
        {
            matches.Add(new Recommendation(
                Category: "dependency-injection",
                Reason: "Service locator usage. Inject dependencies via constructor.",
                Confidence: 0.8));
        }

        // Managed identity — secrets / connection strings with passwords.
        if (Regex.IsMatch(content, @"Password\s*=|AccountKey\s*=|SharedAccessKey\s*=|\bClientSecret\b", RegexOptions.IgnoreCase))
        {
            matches.Add(new Recommendation(
                Category: "managed-identity",
                Reason: "Embedded credentials detected. Switch to Managed Identity + RBAC.",
                Confidence: 0.95));
        }

        if (Regex.IsMatch(content, @"DefaultEndpointsProtocol=https;AccountName=", RegexOptions.IgnoreCase))
        {
            matches.Add(new Recommendation(
                Category: "managed-identity",
                Reason: "Storage connection string with account key. Use `BlobServiceClient(uri, TokenCredential)`.",
                Confidence: 0.95));
        }

        // SOLID — classes with too many responsibilities (rough proxy: many constructor params).
        var ctorMatch = Regex.Match(content, @"public\s+\w+\s*\(([^)]{200,})\)");
        if (ctorMatch.Success && ctorMatch.Groups[1].Value.Count(c => c == ',') >= 5)
        {
            matches.Add(new Recommendation(
                Category: "solid-principles",
                Reason: "Constructor with 6+ parameters — likely Single Responsibility violation.",
                Confidence: 0.6));
        }

        return matches
            .OrderByDescending(m => m.Confidence)
            .ToList();
    }

    private string GetCategoryDirectory(string category)
    {
        if (string.IsNullOrWhiteSpace(category))
        {
            throw new ArgumentException("Category cannot be empty.", nameof(category));
        }

        // Reject anything that smells like traversal or absolute paths.
        if (category.Contains('/') || category.Contains('\\') || category.Contains(".."))
        {
            throw new ArgumentException("Invalid category name.", nameof(category));
        }

        var dir = Path.Combine(_rootPath, category);
        EnsureWithinRoot(dir);

        if (!Directory.Exists(dir))
        {
            throw new DirectoryNotFoundException($"Pattern category not found: {category}");
        }

        return dir;
    }

    private string ResolveCategoryFile(string category, string fileName)
    {
        var path = Path.Combine(GetCategoryDirectory(category), fileName);
        if (!File.Exists(path))
        {
            throw new FileNotFoundException($"{fileName} not found for pattern '{category}'.");
        }

        return path;
    }

    private void EnsureWithinRoot(string path)
    {
        var full = Path.GetFullPath(path);
        if (!full.StartsWith(_rootPath, StringComparison.Ordinal))
        {
            throw new UnauthorizedAccessException("Path resolves outside the patterns root.");
        }
    }

    private static IEnumerable<string> EnumerateSearchableFiles(string dir)
    {
        foreach (var name in new[] { "README.md", "CHECKLIST.md" })
        {
            var path = Path.Combine(dir, name);
            if (File.Exists(path))
            {
                yield return path;
            }
        }

        var examples = Path.Combine(dir, "examples");
        if (Directory.Exists(examples))
        {
            foreach (var file in Directory.EnumerateFiles(examples))
            {
                yield return file;
            }
        }
    }

    private static string? ExtractTitle(string readmePath)
    {
        foreach (var line in File.ReadLines(readmePath))
        {
            if (line.StartsWith("# ", StringComparison.Ordinal))
            {
                return line[2..].Trim();
            }
        }

        return null;
    }

    private static string[] SplitRow(string row) =>
        [.. row.Split('|', StringSplitOptions.RemoveEmptyEntries).Select(c => c.Trim())];

    [GeneratedRegex(@"^\s*-\s*\[([ xX])\]\s*(.+)$")]
    private static partial Regex ChecklistItemRegex();
}

public sealed record PatternSummary(string Category, string Title, bool HasChecklist, int ExampleCount);

public sealed record ChecklistItem(bool Done, string Text);

public sealed record ChecklistSection(string Heading, List<ChecklistItem> Items);

public sealed record ExampleFile(string FileName, string RelativePath, string? Contents);

public sealed record SearchHit(string Category, string RelativePath, int LineNumber, string Snippet);

public sealed record AdoptionRow(string Service, IReadOnlyDictionary<string, string> Statuses);

public sealed record AdoptionMatrix(IReadOnlyList<string> Headers, IReadOnlyList<AdoptionRow> Rows);

public sealed record Recommendation(string Category, string Reason, double Confidence);
