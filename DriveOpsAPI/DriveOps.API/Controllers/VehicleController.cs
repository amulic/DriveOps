
using DriveOps.Application.Interfaces;
using DriveOps.Model;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class VehicleController : ControllerBase
    {
        private readonly ICarService _carService;

       

        //private readonly ILogger<WeatherForecastController> _logger;

        public VehicleController(/*ILogger<WeatherForecastController> logger*/ ICarService carService)
        {
            //_logger = logger;
            _carService = carService;
        }

        [HttpGet(Name = "GetCars")]
        public Car Get()
        {
            return new Car { Make= "m", Model="3" };
        }
    }
}
