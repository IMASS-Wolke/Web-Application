namespace IMASS.Models.SMTHERM_INPUTS
{
    public class MetINDTO
    {
        public int Year { get; set; } //last 2 digits only
        public int JulianDay { get; set; } //1-365
        public int Hour { get; set; } //0-23
        public int Minute { get; set; } //0-59
        public double AmbientAirTemp { get; set; } //kelvin
        public float RelativeHumidity { get; set; } //00.000
        public float WindSpeed { get; set; } //m/sec
        public float IncidentSolarRadiation { get; set; } 
        public float ReflectedSolarRadiation { get; set; }
        public float IncidentLongwaveRadiation { get; set; }
        public float PrecipitationInMHour { get; set; } // m/hr
        public int PrecipitationTypeCode { get; set; } // 0=none, 1=rain, 2=snow or sleet
        public float EffectiveDiamterOrPrecipitationParticle { get; set; } //m
        //Only include cloud conditions if solar or longwave radiation needs to be calculated, otherwise leave blank
        public float LowerCloudCoverage { get; set; } // 0.0 - 1.0
        public int LowerCloudCoverageTypeCode { get; set; } //0=None, 4=Sc 
        public float MiddleCloudCoverage { get; set; } // 0.0 - 1.0
        public int MiddleCloudCoverageTypeCode { get; set; } //0=None, 3=As, Ac or any other
        public float HighCloudCoverage { get; set; } // 0.0 - 1.0
        public int HighCloudCoverageTypeCode { get; set; } //0=None, 1=Ci, 2=Cs


    }
}
