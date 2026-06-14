using System;
using System.Configuration;
using System.IO;
using System.Net.Mail;

namespace OgeFieldOps.Web.Services
{
    /// <summary>
    /// Sends dispatch notifications using System.Net.Mail. Configured (in Web.config) to use a
    /// SpecifiedPickupDirectory, so messages are written as .eml files to a local folder
    /// instead of being sent through a real SMTP server. Classic, testable, no infrastructure.
    /// </summary>
    public class EmailService
    {
        public string PickupDirectory
        {
            get { return ConfigurationManager.AppSettings["NotificationPickupDirectory"]; }
        }

        public string FromAddress
        {
            get { return ConfigurationManager.AppSettings["NotificationFromAddress"] ?? "fieldops-noreply@oge.com"; }
        }

        public string DispatchAddress
        {
            get { return ConfigurationManager.AppSettings["DispatchEmailAddress"] ?? "dispatch@oge.com"; }
        }

        public void SendOutageDocumentNotification(string ticketNumber, string fileName, string uploadedBy)
        {
            var subject = "[OGE FieldOps] Document uploaded for outage " + ticketNumber;
            var body =
                "A new document was uploaded to the OGE Field Operations portal." + Environment.NewLine +
                Environment.NewLine +
                "Outage:     " + ticketNumber + Environment.NewLine +
                "File:       " + fileName + Environment.NewLine +
                "Uploaded by:" + uploadedBy + Environment.NewLine +
                "Time (UTC): " + DateTime.UtcNow.ToString("u") + Environment.NewLine;

            Send(DispatchAddress, subject, body);
        }

        public void SendWorkOrderCreatedNotification(string ticketNumber, string region, string status, string createdBy)
        {
            var subject = "[OGE FieldOps] New work order " + ticketNumber + " (" + region + ")";
            var body =
                "A new work order was logged in the OGE Field Operations portal." + Environment.NewLine +
                Environment.NewLine +
                "Ticket:     " + ticketNumber + Environment.NewLine +
                "Region:     " + region + Environment.NewLine +
                "Status:     " + status + Environment.NewLine +
                "Logged by:  " + createdBy + Environment.NewLine +
                "Time (UTC): " + DateTime.UtcNow.ToString("u") + Environment.NewLine;

            Send(DispatchAddress, subject, body);
        }

        public void Send(string to, string subject, string body)
        {
            var pickup = PickupDirectory;
            if (!string.IsNullOrWhiteSpace(pickup) && !Directory.Exists(pickup))
            {
                Directory.CreateDirectory(pickup);
            }

            using (var message = new MailMessage(FromAddress, to, subject, body))
            using (var client = new SmtpClient())
            {
                // deliveryMethod + pickup directory come from Web.config <system.net><mailSettings>.
                client.Send(message);
            }
        }
    }
}
