using System;
using System.IO;
using System.Text;
using System.Web.Mvc;
using OgeFieldOps.Web.Data;
using OgeFieldOps.Web.Models;
using OgeFieldOps.Web.Services;

namespace OgeFieldOps.Web.Controllers
{
    [Authorize]
    public class OutagesController : Controller
    {
        private readonly OutageRepository _outages = new OutageRepository();
        private readonly FileStorageService _files = new FileStorageService();
        private readonly EmailService _email = new EmailService();
        private readonly AuditLogService _audit = new AuditLogService();

        // GET: /Outages?search=&page=
        public ActionResult Index(string search, int page = 1, int pageSize = 5)
        {
            var result = _outages.Search(search, page, pageSize);
            return View(result);
        }

        // GET: /Outages/Details/5
        public ActionResult Details(int id)
        {
            var outage = _outages.GetById(id);
            if (outage == null)
            {
                return HttpNotFound();
            }
            ViewBag.Documents = _outages.GetDocuments(id);
            return View(outage);
        }

        // GET: /Outages/Upload/5
        public ActionResult Upload(int id)
        {
            var outage = _outages.GetById(id);
            if (outage == null)
            {
                return HttpNotFound();
            }
            return View(new UploadViewModel { OutageId = outage.Id, TicketNumber = outage.TicketNumber });
        }

        // POST: /Outages/Upload
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Upload(UploadViewModel model, System.Web.HttpPostedFileBase document)
        {
            var outage = _outages.GetById(model.OutageId);
            if (outage == null)
            {
                return HttpNotFound();
            }
            model.TicketNumber = outage.TicketNumber;

            if (document == null || document.ContentLength == 0)
            {
                ModelState.AddModelError("", "Please choose a file to upload.");
                return View(model);
            }

            string error;
            if (!_files.IsAllowed(document.FileName, document.ContentLength, out error))
            {
                ModelState.AddModelError("", error);
                return View(model);
            }

            var stored = _files.Save(document);

            _outages.AddDocument(new OutageDocument
            {
                OutageId = outage.Id,
                FileName = stored.FileName,
                StoredPath = stored.StoredPath,
                SizeBytes = stored.SizeBytes,
                UploadedAt = DateTime.UtcNow,
                UploadedBy = User.Identity.Name
            });

            // Fire a dispatch notification (.eml dropped to the pickup directory).
            try
            {
                _email.SendOutageDocumentNotification(outage.TicketNumber, stored.FileName, User.Identity.Name);
            }
            catch (Exception ex)
            {
                _audit.Write(User.Identity.Name, "EMAIL_FAILED", ex.Message);
            }

            _audit.Write(User.Identity.Name, "UPLOAD",
                "Outage=" + outage.TicketNumber + "; File=" + stored.FileName + "; Bytes=" + stored.SizeBytes);

            TempData["Message"] = "Uploaded '" + stored.FileName + "' to outage " + outage.TicketNumber + ".";
            return RedirectToAction("Details", new { id = outage.Id });
        }

        // GET: /Outages/ExportCsv
        public ActionResult ExportCsv()
        {
            var table = _outages.GetAllForExport();
            var sb = new StringBuilder();

            // Header row.
            for (int c = 0; c < table.Columns.Count; c++)
            {
                if (c > 0) sb.Append(',');
                sb.Append(CsvEscape(table.Columns[c].ColumnName));
            }
            sb.Append("\r\n");

            // Data rows.
            foreach (System.Data.DataRow row in table.Rows)
            {
                for (int c = 0; c < table.Columns.Count; c++)
                {
                    if (c > 0) sb.Append(',');
                    sb.Append(CsvEscape(row[c] == DBNull.Value ? string.Empty : row[c].ToString()));
                }
                sb.Append("\r\n");
            }

            _audit.Write(User.Identity.Name, "EXPORT_CSV", "Rows=" + table.Rows.Count);

            var bytes = Encoding.UTF8.GetBytes(sb.ToString());
            return File(bytes, "text/csv", "oge-outages-" + DateTime.UtcNow.ToString("yyyyMMdd") + ".csv");
        }

        private static string CsvEscape(string value)
        {
            if (value == null) return string.Empty;
            if (value.Contains(",") || value.Contains("\"") || value.Contains("\n") || value.Contains("\r"))
            {
                return "\"" + value.Replace("\"", "\"\"") + "\"";
            }
            return value;
        }
    }
}
