using System.Web.Mvc;

namespace OgeFieldOps.Web.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            return RedirectToAction("Index", "Outages");
        }
    }
}
