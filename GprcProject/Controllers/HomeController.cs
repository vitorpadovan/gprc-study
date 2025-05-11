using Microsoft.AspNetCore.Mvc;

namespace GprcProject.Controllers
{
    [ApiController]
    [Route("/")]
    public class HomeController : ControllerBase
    {
        [HttpGet]
        public IActionResult Teste()
        {
            return Ok(new { Teste =123, id=2323 });
        }
    }
}
