using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
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
    }
}
