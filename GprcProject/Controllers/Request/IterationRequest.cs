using System.Text.Json;

namespace GprcProject.Controllers.Request
{
    public class IterationRequest
    {
        public int Usuario { get; set; }
        public int Iteracao { get; set; }

        public override string? ToString()
        {
            return JsonSerializer.Serialize(this);
        }
    }
}
