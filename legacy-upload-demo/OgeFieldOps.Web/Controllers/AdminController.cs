using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web.Mvc;
using OgeFieldOps.Web.Services;

namespace OgeFieldOps.Web.Controllers
{
    /// <summary>
    /// Admin-only pages. The Notifications view lists the .eml files that the SMTP pickup
    /// directory has accumulated - the pre-cloud way to "see what was emailed".
    /// </summary>
    [Authorize(Roles = "Admin")]
    public class AdminController : Controller
    {
        private readonly AuditLogService _audit = new AuditLogService();

        public ActionResult Notifications()
        {
            var pickup = ConfigurationManager.AppSettings["NotificationPickupDirectory"];
            var messages = new List<NotificationFileInfo>();

            if (!string.IsNullOrWhiteSpace(pickup) && Directory.Exists(pickup))
            {
                var files = Directory.GetFiles(pickup, "*.eml")
                    .Select(p => new FileInfo(p))
                    .OrderByDescending(f => f.LastWriteTimeUtc)
                    .Take(50);

                foreach (var file in files)
                {
                    messages.Add(new NotificationFileInfo
                    {
                        FileName = file.Name,
                        SizeBytes = file.Length,
                        CreatedAt = file.LastWriteTimeUtc,
                        Preview = ReadPreview(file.FullName)
                    });
                }
            }

            ViewBag.PickupDirectory = pickup;
            _audit.Write(User.Identity.Name, "VIEW_NOTIFICATIONS", "Count=" + messages.Count);
            return View(messages);
        }

        private static string ReadPreview(string path)
        {
            try
            {
                var lines = File.ReadLines(path).Take(12);
                return string.Join("\n", lines);
            }
            catch
            {
                return "(unable to read)";
            }
        }
    }

    public class NotificationFileInfo
    {
        public string FileName { get; set; }
        public long SizeBytes { get; set; }
        public DateTime CreatedAt { get; set; }
        public string Preview { get; set; }
    }
}
