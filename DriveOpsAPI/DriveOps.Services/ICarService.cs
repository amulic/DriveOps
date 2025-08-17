using DriveOps.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.Services
{
    public interface ICarService
    {
        IList<Car> get();
    }
}
