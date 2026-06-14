using System;
using System.IO;
using System.Text;
using System.Web.Mvc;
using OgeFieldOps.Web.Data;
using OgeFieldOps.Web.Models;
using OgeFieldOps.Web.Services;

namespace OgeFieldOps.Web.Controllers
{
    public class OutagesController : Controller
    {
        // Wide-open app: no login, so uploads/exports are attributed to a generic user.
        private const string CurrentUser = "anonymous";

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

        // GET: /Outages/Create
        public ActionResult Create()
        {
            var workOrder = new WorkOrderViewModel
            {
                Status = "Reported",
                ReportedAt = DateTime.Now
            };
            ViewBag.StatusOptions = BuildStatusOptions(workOrder.Status);
            return View(workOrder);
        }

        // POST: /Outages/Create
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create(WorkOrderViewModel model)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.StatusOptions = BuildStatusOptions(model.Status);
                return View(model);
            }

            var ticketNumber = _outages.GetNextTicketNumber();
            var reportedBy = string.IsNullOrWhiteSpace(model.ReportedBy) ? CurrentUser : model.ReportedBy.Trim();

            var id = _outages.Create(new OutageRecord
            {
                TicketNumber = ticketNumber,
                Region = model.Region,
                Cause = model.Cause,
                Status = model.Status,
                CustomersAffected = model.CustomersAffected,
                ReportedAt = model.ReportedAt,
                ReportedBy = reportedBy
            });

            // Fire a dispatch notification (.eml dropped to the pickup directory).
            try
            {
                _email.SendWorkOrderCreatedNotification(ticketNumber, model.Region, model.Status, reportedBy);
            }
            catch (Exception ex)
            {
                _audit.Write(reportedBy, "EMAIL_FAILED", ex.Message);
            }

            _audit.Write(reportedBy, "WORKORDER_CREATE",
                "Ticket=" + ticketNumber + "; Region=" + model.Region + "; Status=" + model.Status);

            TempData["Message"] = "Created work order " + ticketNumber + ".";
            return RedirectToAction("Details", new { id = id });
        }

        private static SelectList BuildStatusOptions(string selected)
        {
            var statuses = new[] { "Reported", "In Progress", "Restored" };
            return new SelectList(statuses, selected);
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
                UploadedBy = CurrentUser
            });

            // Fire a dispatch notification (.eml dropped to the pickup directory).
            try
            {
                _email.SendOutageDocumentNotification(outage.TicketNumber, stored.FileName, CurrentUser);
            }
            catch (Exception ex)
            {
                _audit.Write(CurrentUser, "EMAIL_FAILED", ex.Message);
            }

            _audit.Write(CurrentUser, "UPLOAD",
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

            _audit.Write(CurrentUser, "EXPORT_CSV", "Rows=" + table.Rows.Count);

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
