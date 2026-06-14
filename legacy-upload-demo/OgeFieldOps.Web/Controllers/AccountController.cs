using System.Web.Mvc;
using System.Web.Security;
using OgeFieldOps.Web.Data;
using OgeFieldOps.Web.Models;
using OgeFieldOps.Web.Services;

namespace OgeFieldOps.Web.Controllers
{
    [Authorize]
    public class AccountController : Controller
    {
        private readonly UserRepository _users = new UserRepository();
        private readonly AuditLogService _audit = new AuditLogService();

        [AllowAnonymous]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View(new LoginViewModel { ReturnUrl = returnUrl });
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public ActionResult Login(LoginViewModel model)
        {
            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var user = _users.ValidateCredentials(model.Username, model.Password);
            if (user == null)
            {
                _audit.Write(model.Username, "LOGIN_FAILED", "Invalid credentials");
                ModelState.AddModelError("", "Invalid username or password.");
                return View(model);
            }

            // Classic Forms Authentication ticket; role carried in the cookie userData.
            var ticket = new FormsAuthenticationTicket(
                1, user.Username, System.DateTime.Now, System.DateTime.Now.AddMinutes(60),
                false, user.Role, FormsAuthentication.FormsCookiePath);
            var encrypted = FormsAuthentication.Encrypt(ticket);
            var cookie = new System.Web.HttpCookie(FormsAuthentication.FormsCookieName, encrypted);
            Response.Cookies.Add(cookie);

            _audit.Write(user.Username, "LOGIN_SUCCESS", "Role=" + user.Role);

            if (!string.IsNullOrEmpty(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
            {
                return Redirect(model.ReturnUrl);
            }
            return RedirectToAction("Index", "Outages");
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Logout()
        {
            _audit.Write(User != null && User.Identity != null ? User.Identity.Name : null, "LOGOUT", "");
            FormsAuthentication.SignOut();
            return RedirectToAction("Login");
        }
    }
}
