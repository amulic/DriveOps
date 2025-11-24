using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestController : ControllerBase
    {
        [HttpGet("public")]
        public IActionResult Get() => Ok("Public OK");

        [Authorize]
        [HttpGet]
        public IActionResult Secure() => Ok($"Secure OK for user: {User.Identity.Name}");
    }
}
