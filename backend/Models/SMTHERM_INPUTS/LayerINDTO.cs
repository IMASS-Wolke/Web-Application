namespace IMASS.Models.SMTHERM_INPUTS
{
    public class LayerINDTO
    {
        public int LayerCount { get; set; }
        public int PrintOutInterval { get; set; }
        public int HourlyPrintOuts { get; set; } // 0 = no, 1 = yes
        public double AvgBaroMeticPressureOverPeriod { get; set; } //mb
        public int EstSolarRadiation { get; set; } //0 = no, 1 = yes, 2 = estimate missing values only
        public int EstIncidentLongwaveRadiation {get;set;} //0 = no, 1 = yes
        public int SlopedTerrain { get; set; } //0 = no, 1 = yes
        public int SnowCompacted { get; set; } //0 = no, 1 = yes (tank tracks, unsure of meaning)
        public double IR_Extinction_Coeff_TopSnowNode { get; set; }
        public int Optional_input_for_Measured_TempData { get; set; } //0 = no, 1 = yes
        public int Optional_printOut_WaterInfiltration_Estimates { get; set; } //0 = no, 1 = yes , CAN GENERATE EXTENSIVE OUTPUT
        public double Basic_TimePeriod_Seconds { get; set; } //time step in seconds EX: 3600
        public int Estimate_Standard_MET_Data { get; set; } //0 = no, 1 = yes
        public double Snow_Albedo { get; set; } //0-1
        public double Irreducible_Water_Saturation_Snow { get; set; } 
        //END OF LINE 1

        public double Air_Temp_Height { get; set; }
        public double Wind_Speed_Height { get; set; }
        public double Dew_Point_Temp_Height { get; set; }

        //END OF LINE 2
        public int Number_Of_Nodes { get; set; } 
        public int Material_Code { get; set; } // 1 = snow, 2 = soil, 3 = sand, 90..99 = user supplied material
        public double Quartz_Content { get; set; }
        public double Roughness_Length { get;set; } // .001 - .002 or 999
        public double Bulk_Transfer_Coeff_EddyDiffusivity { get; set; }
        public double Turbulent_Schmidt_Number { get; set; }
        public double Turbulent_Prandtl_Number { get; set; }
        public double Windless_Convection_Coeff_LatentHeat { get; set; }
        public double Windless_Convection_Coeff_SensibleHeat { get; set; }
        public double Fractional_Humidity_Relative_To_Saturated_State { get; set; } // 1.0 for snow, <=1.0 for soil
        //END OF LINE 3
        public int Num_Of_Successful_Calcs_Before_IncreasingTimeStep { get; set; }
        public int Min_Allowable_TimeStep_Seconds { get; set; }
        public int Min_Allowable_TimeStep_With_Waterflow_Present { get; set; } //cant exceed 10
        public double Max_Allowable_TimeSteps_Seconds { get; set; } //cant exceed 900
        public double Max_Allowable_TimeStep__With_Waterflow_Present { get; set; }
        public double Max_Allowable_Change_In_Saturation_Per_TimeStep { get; set; }
        public double Max_Allowable_Temp_Est_Error_Per_TimeStep { get; set; } //celsius
        //END OF LINE 4


    }
}
