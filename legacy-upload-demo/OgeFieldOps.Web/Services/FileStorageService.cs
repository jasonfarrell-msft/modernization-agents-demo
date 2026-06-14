using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;

namespace OgeFieldOps.Web.Services
{
    public class StoredFileResult
    {
        public string FileName { get; set; }
        public string StoredPath { get; set; }
        public long SizeBytes { get; set; }
    }

    /// <summary>
    /// Writes uploaded files to a server-local directory defined in Web.config
    /// (appSettings["UploadDirectory"]). Classic pre-cloud "save to a file share" pattern.
    /// </summary>
    public class FileStorageService
    {
        public string UploadDirectory
        {
            get { return ConfigurationManager.AppSettings["UploadDirectory"]; }
        }

        public IList<string> AllowedExtensions
        {
            get
            {
                var raw = ConfigurationManager.AppSettings["AllowedUploadExtensions"] ?? string.Empty;
                return raw.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                          .Select(x => x.Trim().ToLowerInvariant())
                          .ToList();
            }
        }

        public int MaxUploadSizeMb
        {
            get
            {
                int mb;
                return int.TryParse(ConfigurationManager.AppSettings["MaxUploadSizeMb"], out mb) ? mb : 25;
            }
        }

        public bool IsAllowed(string fileName, long sizeBytes, out string error)
        {
            error = null;
            var ext = (Path.GetExtension(fileName) ?? string.Empty).ToLowerInvariant();
            var allowed = AllowedExtensions;
            if (allowed.Count > 0 && !allowed.Contains(ext))
            {
                error = "File type '" + ext + "' is not allowed. Allowed: " + string.Join(", ", allowed);
                return false;
            }
            if (sizeBytes > (long)MaxUploadSizeMb * 1024 * 1024)
            {
                error = "File exceeds the maximum size of " + MaxUploadSizeMb + " MB.";
                return false;
            }
            return true;
        }

        public StoredFileResult Save(HttpPostedFileBase file)
        {
            if (file == null || file.ContentLength == 0)
            {
                throw new InvalidOperationException("Please choose a file to upload.");
            }

            var directory = UploadDirectory;
            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            var originalName = Path.GetFileName(file.FileName).Replace("..", "_");
            var storedName = DateTime.UtcNow.ToString("yyyyMMddHHmmssfff") + "-" + originalName;
            var storedPath = Path.Combine(directory, storedName);

            file.SaveAs(storedPath);

            return new StoredFileResult
            {
                FileName = originalName,
                StoredPath = storedPath,
                SizeBytes = file.ContentLength
            };
        }
    }
}
