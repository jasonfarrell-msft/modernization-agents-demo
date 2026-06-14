using System;
using System.ComponentModel.DataAnnotations;

namespace OgeFieldOps.Web.Models
{
    /// <summary>
    /// Data-entry model for logging a new outage work order. The ticket number is
    /// generated server-side, so it is not part of the form.
    /// </summary>
    public class WorkOrderViewModel
    {
        [Required]
        [StringLength(64)]
        [Display(Name = "Region")]
        public string Region { get; set; }

        [Required]
        [StringLength(128)]
        [Display(Name = "Cause")]
        public string Cause { get; set; }

        [Required]
        [Display(Name = "Status")]
        public string Status { get; set; }

        [Range(0, 1000000, ErrorMessage = "Customers affected must be between 0 and 1,000,000.")]
        [Display(Name = "Customers affected")]
        public int CustomersAffected { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        [Display(Name = "Reported at")]
        public DateTime ReportedAt { get; set; }

        [StringLength(64)]
        [Display(Name = "Reported by")]
        public string ReportedBy { get; set; }
    }
}
