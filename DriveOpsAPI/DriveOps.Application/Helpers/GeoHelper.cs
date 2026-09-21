namespace DriveOps.Application.Helpers
{
    public static class GeoHelper
    {
        private const double EarthRadiusKm = 6371.0;

        /// <summary>Haversine distance between two coordinates in kilometres.</summary>
        public static double DistanceKm(decimal lat1, decimal lon1, decimal lat2, decimal lon2)
        {
            double dLat = ToRadians((double)(lat2 - lat1));
            double dLon = ToRadians((double)(lon2 - lon1));

            double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(ToRadians((double)lat1)) * Math.Cos(ToRadians((double)lat2))
                * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            return 2 * EarthRadiusKm * Math.Asin(Math.Sqrt(a));
        }

        private static double ToRadians(double degrees) => degrees * Math.PI / 180.0;
    }
}
