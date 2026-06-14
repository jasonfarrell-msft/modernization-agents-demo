using System.Web.Mvc;

namespace OgeFieldOps.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return RedirectToAction("Index", "Outages");
        }
    }
}
