using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.SqlServer;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LegacyUploadDemo.Azure.Database;

/// <summary>
/// Demonstrates Azure SQL Database with Serverless compute + Managed Identity pattern.
/// Always use Managed Identity for authentication.
/// Enable retry logic for serverless auto-pause recovery.
/// Never use SQL authentication (username/password).
/// </summary>
public static class SqlServerConfiguration
{
    /// <summary>
    /// Register EF Core DbContext with Managed Identity authentication.
    /// Connection string uses Azure AD Managed Identity, not SQL auth.
    /// </summary>
    public static IServiceCollection AddSqlDatabase(this IServiceCollection services, IConfiguration config)
    {
        var serverName = config["Azure:Sql:ServerName"] 
            ?? throw new InvalidOperationException("Azure:Sql:ServerName is required");
        
        var databaseName = config["Azure:Sql:DatabaseName"] 
            ?? throw new InvalidOperationException("Azure:Sql:DatabaseName is required");
        
        // Connection string with Managed Identity authentication
        // Do NOT include username, password, or User ID
        var connectionString = $"Server=tcp:{serverName}.database.windows.net,1433;Initial Catalog={databaseName};" +
                               $"Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;" +
                               $"Authentication=Active Directory Managed Identity";
        
        services.AddDbContext<OutageContext>(options =>
        {
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                // Enable retry logic for transient failures (including serverless auto-pause)
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelaySeconds: 5,
                    errorNumbersToAdd: null);
                
                // Use exponential backoff for serverless recovery
                sqlOptions.CommandTimeout(30);
            });
        });
        
        return services;
    }
}

/// <summary>
/// EF Core DbContext for legacy-upload-demo.
/// Demonstrates serverless-compatible Entity Framework usage.
/// </summary>
public class OutageContext : DbContext
{
    public OutageContext(DbContextOptions<OutageContext> options) : base(options) { }
    
    public DbSet<Outage> Outages { get; set; } = null!;
    public DbSet<Document> Documents { get; set; } = null!;
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Configure Outage entity
        modelBuilder.Entity<Outage>().HasKey(o => o.Id);
        modelBuilder.Entity<Outage>()
            .Property(o => o.CreatedAt)
            .HasDefaultValueSql("GETUTCDATE()");
        
        // Configure Document entity
        modelBuilder.Entity<Document>().HasKey(d => d.Id);
        modelBuilder.Entity<Document>()
            .Property(d => d.UploadedAt)
            .HasDefaultValueSql("GETUTCDATE()");
        
        // Relationships
        modelBuilder.Entity<Document>()
            .HasOne<Outage>()
            .WithMany()
            .HasForeignKey(d => d.OutageId);
    }
}

/// <summary>
/// Outage entity for legacy-upload-demo database.
/// </summary>
public class Outage
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

/// <summary>
/// Document entity - represents uploaded files.
/// Metadata is stored in SQL; actual file content is in Blob Storage.
/// </summary>
public class Document
{
    public int Id { get; set; }
    public int OutageId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string BlobUri { get; set; } = string.Empty;  // Reference to Blob Storage
    public long FileSizeBytes { get; set; }
    public string ContentType { get; set; } = string.Empty;
    public string UploadedBy { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}

/// <summary>
/// Example repository using EF Core with async operations.
/// Demonstrates serverless-compatible patterns (async, retry-aware, connection pooling enabled).
/// </summary>
public class OutageRepository
{
    private readonly OutageContext _context;
    
    public OutageRepository(OutageContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
    }
    
    /// <summary>
    /// Retrieve an outage by ID.
    /// Uses async operation compatible with serverless database.
    /// </summary>
    public async Task<Outage?> GetOutageByIdAsync(int outageId)
    {
        // Async operation - critical for serverless scenarios
        return await _context.Outages.FirstOrDefaultAsync(o => o.Id == outageId);
    }
    
    /// <summary>
    /// Save changes to the database.
    /// Retry logic is handled by DbContext configuration (EnableRetryOnFailure).
    /// </summary>
    public async Task SaveChangesAsync()
    {
        // SaveChangesAsync will automatically retry on transient failures
        await _context.SaveChangesAsync();
    }
    
    /// <summary>
    /// Add a document record to the database.
    /// Actual file content is stored in Blob Storage; this records metadata.
    /// </summary>
    public async Task AddDocumentAsync(Document document)
    {
        _context.Documents.Add(document);
        await _context.SaveChangesAsync();
    }
    
    /// <summary>
    /// Get documents for an outage.
    /// </summary>
    public async Task<List<Document>> GetDocumentsByOutageIdAsync(int outageId)
    {
        return await _context.Documents
            .Where(d => d.OutageId == outageId)
            .ToListAsync();
    }
}
