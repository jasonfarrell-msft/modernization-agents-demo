using Microsoft.AspNetCore.Http;
using Microsoft.Data.Sqlite;

namespace LegacyUploadDemo.Web.Services;

public interface ILegacyUploadService
{
    Task<LegacyUploadSnapshot> GetSnapshotAsync();
    Task<string> SaveUploadAsync(IFormFile file);
}

public sealed record LegacyUploadSnapshot(
    string UploadDirectory,
    IReadOnlyList<string> Files,
    int DatabaseRecordCount,
    string DatabaseStatus);

public sealed class LegacyUploadService : ILegacyUploadService
{
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;

    public LegacyUploadService(IConfiguration configuration, IWebHostEnvironment environment)
    {
        _configuration = configuration;
        _environment = environment;
    }

    public Task<LegacyUploadSnapshot> GetSnapshotAsync()
    {
        var uploadDirectory = ResolveUploadDirectory();
        Directory.CreateDirectory(uploadDirectory);

        var files = Directory
            .GetFiles(uploadDirectory)
            .OrderByDescending(path => new FileInfo(path).LastWriteTimeUtc)
            .Select(path => Path.GetFileName(path))
            .ToArray();

        var databaseRecordCount = 0;
        var databaseStatus = "Local database is ready for demo events.";

        try
        {
            var connectionString = _configuration.GetConnectionString("LegacyDb")
                ?? "Data Source=legacy-upload-demo.db";

            using var connection = new SqliteConnection(connectionString);
            connection.Open();

            using var createTable = connection.CreateCommand();
            createTable.CommandText = "CREATE TABLE IF NOT EXISTS UploadEvents (Id INTEGER PRIMARY KEY AUTOINCREMENT, FileName TEXT NOT NULL, StoredAt TEXT NOT NULL, StoredPath TEXT NOT NULL);";
            createTable.ExecuteNonQuery();

            using var countCommand = connection.CreateCommand();
            countCommand.CommandText = "SELECT COUNT(*) FROM UploadEvents";
            databaseRecordCount = Convert.ToInt32(countCommand.ExecuteScalar());
        }
        catch (Exception ex)
        {
            databaseStatus = $"Database check failed: {ex.Message}";
        }

        return Task.FromResult(new LegacyUploadSnapshot(uploadDirectory, files, databaseRecordCount, databaseStatus));
    }

    public async Task<string> SaveUploadAsync(IFormFile file)
    {
        if (file is null || file.Length == 0)
        {
            throw new InvalidOperationException("Please choose a file to upload.");
        }

        var uploadDirectory = ResolveUploadDirectory();
        Directory.CreateDirectory(uploadDirectory);

        var sanitizedFileName = Path.GetFileName(file.FileName).Replace("..", "_");
        var targetPath = Path.Combine(uploadDirectory, $"{DateTime.UtcNow:yyyyMMddHHmmssfff}-{sanitizedFileName}");

        await using (var stream = File.Create(targetPath))
        {
            await file.CopyToAsync(stream);
        }

        var connectionString = _configuration.GetConnectionString("LegacyDb")
            ?? "Data Source=legacy-upload-demo.db";

        try
        {
            using var connection = new SqliteConnection(connectionString);
            await connection.OpenAsync();

            using var createTable = connection.CreateCommand();
            createTable.CommandText = "CREATE TABLE IF NOT EXISTS UploadEvents (Id INTEGER PRIMARY KEY AUTOINCREMENT, FileName TEXT NOT NULL, StoredAt TEXT NOT NULL, StoredPath TEXT NOT NULL);";
            await createTable.ExecuteNonQueryAsync();

            using var insertCommand = connection.CreateCommand();
            insertCommand.CommandText = "INSERT INTO UploadEvents (FileName, StoredAt, StoredPath) VALUES (@fileName, @storedAt, @storedPath);";
            insertCommand.Parameters.AddWithValue("@fileName", file.FileName);
            insertCommand.Parameters.AddWithValue("@storedAt", DateTimeOffset.UtcNow.ToString("O"));
            insertCommand.Parameters.AddWithValue("@storedPath", targetPath);
            await insertCommand.ExecuteNonQueryAsync();
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Upload saved to disk, but the local database write failed: {ex.Message}", ex);
        }

        return targetPath;
    }

    private string ResolveUploadDirectory()
    {
        var configuredDirectory = _configuration["UploadDirectory"];
        return string.IsNullOrWhiteSpace(configuredDirectory)
            ? Path.Combine(_environment.ContentRootPath, "uploads")
            : Path.IsPathRooted(configuredDirectory)
                ? configuredDirectory
                : Path.Combine(_environment.ContentRootPath, configuredDirectory);
    }
}
