using System;
using System.Collections.Generic;

namespace OgeFieldOps.Web.Models
{
    public class OutageRecord
    {
        public int Id { get; set; }
        public string TicketNumber { get; set; }
        public string Region { get; set; }
        public string Cause { get; set; }
        public string Status { get; set; }
        public int CustomersAffected { get; set; }
        public DateTime ReportedAt { get; set; }
        public DateTime? RestoredAt { get; set; }
        public string ReportedBy { get; set; }
    }

    public class OutageDocument
    {
        public int Id { get; set; }
        public int OutageId { get; set; }
        public string FileName { get; set; }
        public string StoredPath { get; set; }
        public long SizeBytes { get; set; }
        public DateTime UploadedAt { get; set; }
        public string UploadedBy { get; set; }
    }

    /// <summary>Paged result for the outage list (server-side paging).</summary>
    public class OutageListResult
    {
        public IList<OutageRecord> Items { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalCount { get; set; }
        public string Search { get; set; }

        public int TotalPages
        {
            get { return PageSize <= 0 ? 0 : (int)Math.Ceiling((double)TotalCount / PageSize); }
        }
    }
}
