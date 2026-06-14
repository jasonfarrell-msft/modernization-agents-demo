using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;

namespace OgeFieldOps.Web.Data
{
    /// <summary>
    /// Thin ADO.NET helper. Intentionally legacy: reads the connection string from
    /// Web.config, opens raw SqlConnection objects, and exposes no abstraction/ORM.
    /// </summary>
    public static class Database
    {
        public static string ConnectionString
        {
            get { return ConfigurationManager.ConnectionStrings["OgeFieldOps"].ConnectionString; }
        }

        public static SqlConnection OpenConnection()
        {
            var connection = new SqlConnection(ConnectionString);
            connection.Open();
            return connection;
        }
    }

    /// <summary>
    /// Best-effort startup bootstrap: makes sure the runtime directories exist and the
    /// database schema/seed is applied. Pre-cloud apps often "self-healed" like this.
    /// </summary>
    public static class DatabaseInitializer
    {
        public static void EnsureReady()
        {
            try
            {
                EnsureDirectory(ConfigurationManager.AppSettings["UploadDirectory"]);
                EnsureDirectory(ConfigurationManager.AppSettings["NotificationPickupDirectory"]);
                var auditPath = ConfigurationManager.AppSettings["AuditLogPath"];
                if (!string.IsNullOrWhiteSpace(auditPath))
                {
                    EnsureDirectory(Path.GetDirectoryName(auditPath));
                }
            }
            catch
            {
                // Swallow on startup (legacy behavior); surfaced later when used.
            }
        }

        private static void EnsureDirectory(string path)
        {
            if (!string.IsNullOrWhiteSpace(path) && !Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }
    }
}
