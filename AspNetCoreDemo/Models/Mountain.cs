using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace AspNetCoreDemo.Models
{
    public class Mountain
    {
        public int MountainId { get; set; }
        public string Name { get; set; }
        public string Location { get; set; }
        public decimal HeightKM { get; set; }
    }
}
