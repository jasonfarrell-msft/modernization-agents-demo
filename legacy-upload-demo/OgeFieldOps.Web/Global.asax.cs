using System;
using System.Security.Principal;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using OgeFieldOps.Web.Data;

namespace OgeFieldOps.Web
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            // Ensure the database exists / is reachable and runtime directories are present.
            DatabaseInitializer.EnsureReady();
        }

        // Rehydrate the user's role (stored in the Forms ticket UserData at login) into the
        // request principal so [Authorize(Roles=...)] and User.IsInRole(...) work.
        protected void Application_PostAuthenticateRequest(object sender, EventArgs e)
        {
            var authCookie = Context.Request.Cookies[FormsAuthentication.FormsCookieName];
            if (authCookie == null || string.IsNullOrEmpty(authCookie.Value))
            {
                return;
            }

            try
            {
                var ticket = FormsAuthentication.Decrypt(authCookie.Value);
                if (ticket == null || ticket.Expired)
                {
                    return;
                }

                var roles = string.IsNullOrEmpty(ticket.UserData)
                    ? new string[0]
                    : new[] { ticket.UserData };

                var identity = new FormsIdentity(ticket);
                Context.User = new GenericPrincipal(identity, roles);
            }
            catch
            {
                // Invalid/tampered cookie - leave the request unauthenticated.
            }
        }
    }
}
