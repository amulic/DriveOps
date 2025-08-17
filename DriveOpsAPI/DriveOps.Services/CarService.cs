using DriveOps.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DriveOps.Services
{
    public class CarService : ICarService
    {
        List<Car> cars = new List<Car>() { 
            new Car()
            {
                Id = 1,
                Make = "Mazda",
                Model = "3"
            }
        };

        public IList<Car> get()
        {
            return cars;
        }
    }
}
