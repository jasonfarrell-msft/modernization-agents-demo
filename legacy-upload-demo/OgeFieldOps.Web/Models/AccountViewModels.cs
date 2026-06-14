using System.ComponentModel.DataAnnotations;

namespace OgeFieldOps.Web.Models
{
    public class UploadViewModel
    {
        [Required]
        [Display(Name = "Outage ticket")]
        public int OutageId { get; set; }

        public string TicketNumber { get; set; }
    }
}
