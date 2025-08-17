using DriveOps.Model;
using DriveOps.Services;
using Microsoft.AspNetCore.Mvc;

namespace DriveOps.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CarController : ControllerBase
    {
        private readonly ICarService _carService;

        private readonly ILogger<WeatherForecastController> _logger;

        public CarController(ILogger<WeatherForecastController> logger, ICarService carService)
        {
            _logger = logger;
            _carService = carService;
        }

        [HttpGet(Name = "GetCars")]
        public IEnumerable<Car> Get()
        {
            return _carService.get();
        }
    }
}
