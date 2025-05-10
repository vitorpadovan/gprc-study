using GprcProject.Controllers.Request;
using Microsoft.AspNetCore.Mvc;

namespace GprcProject.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : ControllerBase
    {
        private readonly ILogger<OrderController> _logger;

        public OrderController(ILogger<OrderController> logger)
        {
            _logger = logger;
        }

        [HttpPost]
        public void SaveOrder([FromBody] IterationRequest iterationRequest)
        {
            _logger.LogInformation("O que estamos recebendo é {dd}",iterationRequest);
        }
    }
}
