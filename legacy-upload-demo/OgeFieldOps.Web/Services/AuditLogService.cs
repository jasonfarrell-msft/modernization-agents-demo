using System;
using System.Configuration;
using System.IO;
using System.Text;

namespace OgeFieldOps.Web.Services
{
    /// <summary>
    /// Appends plain-text audit lines to a server-local log file defined in Web.config
    /// (appSettings["AuditLogPath"]). Pre-cloud "log to a file on disk" pattern.
    /// </summary>
    public class AuditLogService
    {
        public string LogPath
        {
            get { return ConfigurationManager.AppSettings["AuditLogPath"]; }
        }

        public void Write(string user, string action, string detail)
        {
            try
            {
                var path = LogPath;
                if (string.IsNullOrWhiteSpace(path))
                {
                    return;
                }

                var directory = Path.GetDirectoryName(path);
                if (!string.IsNullOrWhiteSpace(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                var line = string.Format("{0:u}\t{1}\t{2}\t{3}{4}",
                    DateTime.UtcNow, user ?? "(anonymous)", action ?? string.Empty, detail ?? string.Empty,
                    Environment.NewLine);

                File.AppendAllText(path, line, Encoding.UTF8);
            }
            catch
            {
                // Never let audit logging break the request (legacy behavior).
            }
        }
    }
}
