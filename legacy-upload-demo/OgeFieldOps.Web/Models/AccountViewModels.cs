using System.ComponentModel.DataAnnotations;

namespace OgeFieldOps.Web.Models
{
    public class LoginViewModel
    {
        [Required]
        [Display(Name = "Username")]
        public string Username { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        public string ReturnUrl { get; set; }
    }

    public class UploadViewModel
    {
        [Required]
        [Display(Name = "Outage ticket")]
        public int OutageId { get; set; }

        public string TicketNumber { get; set; }
    }
}
