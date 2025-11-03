
using DriveOps.Application.Interfaces;
using DriveOps.Infrastructure.Persistence;
using DriveOps.Model;
using DriveOps.Model.Entity;
using DriveOps.Model.Enums;
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
        private ApplicationDbContext _db;
       

        //private readonly ILogger<WeatherForecastController> _logger;

        public VehicleController(/*ILogger<WeatherForecastController> logger*/ ICarService carService, ApplicationDbContext context)
        {
            //_logger = logger;
            _carService = carService;
            _db = context;
        }

        [HttpGet(Name = "GetCars")]
        public Vehicle Get()
        {
            return _db.Vehicles.ToList()[0];
        }
    }
}
