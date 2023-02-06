using DataFrames
using CSV
using Query
using Dates

struct Buoys
    IDNumber::Int64
    Depth::Float64
    DistFromShore::Float64
end

struct BuoyDF
    yearsIncluded::Any
    BuoyRepresented::Buoys
    ColumnsContained::Array
    MissingValue::Any
end


struct Columns
    shortName::Symbol
    formalName::String
    units::String
    uncertainty::Float64
    errorValue::Vector{Number}
    info::String
    defaultBins::Int64
    normalLimits::Vector{Number}
end

#=
Want to be explicit
If we can agree on one abbreviation that doesn't conflict and is used often, it is fine, we just need to keep track. 
=#
DateTimeCol = Columns(:dt, "Date/Time", " ", 0, [99.0], "GMT/UTC", 31, [])
YearCol = Columns(:yr,"Year"," ", 0, [99.0], "GMT/UTC", 50, [0, 2022])
MonthCol = Columns(:mo,"Month"," ", 0, [99.0], "GMT/UTC", 12, [1, 12])
DayCol = Columns(:day,"Day"," ", 0, [99.0], "GMT/UTC", 31, [1, 31])
HourCol = Columns(:hr,"Hour"," ", 0, [99.0], "GMT/UTC", 24, [0, 24])
MinCol = Columns(:min,"Minutes"," ", 0, [99.0], "GMT/UTC", 12, [0, 60])
WindDirCol = Columns(:wdir,"Wind Direction","Degrees CW from North", 0, [999.0], 
"Wind direction (the direction the wind is coming from in degrees clockwise from true N) during the same period used for WSPD", 36, [0, 360])
WindSpdCol = Columns(:wspd,"Wind Speed","m/s",0.0,[99.0], "Wind speed (m/s) averaged over an eight-minute period for buoys and a two-minute period for land stations.", 40, [0, 98])
GustSpdCol = Columns(:gst,"Wind Gust Speed","m/s",0.0,[99.0], "Peak 5 or 8 second gust speed (m/s) measured during the eight-minute or two-minute period. The 5 or 8 second period can be determined by payload, See the Sensor Reporting, Sampling, and Accuracy section", 40, [0, 98])
WaveHtCol =  Columns(:wht,"Wave Height","m", 0.5, [99.0], "Significant wave height (meters) is calculated as the average of the highest one-third of all of the wave heights during the 20-minute sampling period. See the Wave Measurements section.", 30, [0, 20]) 
DomWavePeriodCol = Columns(:dpd,"Dominant Wave Period", "Seconds",0.0,[99.0], "Dominant wave period (seconds) is the period with the maximum wave energy.", 50, [0, 10]) 
AvWavePeriodCol = Columns(:apd,"Average Wave Period", "Seconds",0.0,[99.0], "Average wave period (seconds) of all waves during the 20-minute period.", 50, [0, 10])  
DomWaveDirCol = Columns(:mwd,"Direction of Dominant Wave Period","Degrees Clockwise from North",0.0,[999.0],
"The direction from which the waves at the dominant period (DPD) are coming. The units are degrees from true North, increasing clockwise, with North as 0 (zero) degrees and East as 90 degrees. See the Wave Measurements section.", 36, [0, 360]) 
SeaPressureCol = Columns(:pr,"Sea Level Pressure","hPa",0.0,[999.0], "Sea level pressure (hPa)", 30, [1000, 1200]) 
AirTempCol = Columns(:atmp,"Air Temperature","Celsius",0.0,[99.0], " ", 50, [-30, 70]) 
WaterTempCol = Columns(:wtmp,"Sea Surface Temperature","Celsius",0.0,[99.0], " ", 50, [-30, 70]) 
DewPointTempCol = Columns(:dew,"Dewpoint Temperature", "Celsius?",0.0,[99.0], "Dewpoint temperature taken at the same height as the air temperature measurement.", 50, [-30, 70]) 
VisibilityCol = Columns(:vis,"Station Visibility","Nautical Miles",0.0,[99.0], "Station visibility (nautical miles). Note that buoy stations are limited to reports from 0 to 1.6 nmi.", 32, [0, 1.6]) 
TidalWaterLevelCol = Columns(:tide,"Water Level","Feet above MLLW",0.0,[99.0], "The water level in feet above or below Mean Lower Low Water (MLLW).", 25, [0, 60]) 

DefaultColumns = [YearCol, MonthCol, DayCol, HourCol, MinCol, WindDirCol, WindSpdCol, GustSpdCol, WaveHtCol, DomWavePeriodCol, AvWavePeriodCol, DomWaveDirCol, SeaPressureCol, AirTempCol, WaterTempCol,
DewPointTempCol, VisibilityCol, TidalWaterLevelCol]

DefaultHeaders = []
for column in DefaultColumns
    push!(DefaultHeaders, column.shortName)
end

function formatFileToDataFrame(filePath, numOfHeaders)
    #=
    formatFileToDataFrame is a function which will turn a given CSV or Text file into a DataFrame with the default header names, and
    then returns that DataFrame.
    NOTE: only works with a correctly formatted file, all columns must be in the correct order, and there must be one header line. 
    This is how the complete files that Zander's code produces will be formatted

    PARAMETERS:
    filePath: A string that is the file path to the CSV or text file. 

    RETURNS: m  the file given.
    =#
    df = CSV.read(filePath, DataFrame, header=1:numOfHeaders, delim=" ", ignorerepeated=true)
    columnObjIndex = 1
    for colName in names(df)
        rename!(df, [colName => DefaultColumns[columnObjIndex].shortName])
        columnObjIndex += 1
    end
    return df
end

#YearCol.formalName

function formattedCSVToDataFrame(filePath)
    df = CSV.read(filePath, DataFrame)
    columnObjIndex = 1
    for colName in names(df)
        rename!(df, [colName => DefaultColumns[columnObjIndex].shortName])
        columnObjIndex += 1
    end
    return df
end

function changeDateFormatToDateTime(df)
    #=
    changeDateFormatToDateTime changes the given DataFrame object from the original seperated time unit 
    columns format that the buoy data is downloaded in, to a format which has all of the time columns combined 
    into one column of DateTime objects. 

    PARAMETERS:
    df: This is the DataFrame object that will be reformatted

    RETURNS:
    temporaryDF: A DataFrame object with the same data as the given df, but has the years, months, days, 
    hours, and minutes put together into one column of DateTime objects instead of seperate columns 
    =#
    dateTimeColumn = DataFrame(temporaryName = DateTime[])
    for row in eachrow(df)
        dateTime = "$(row[MonthCol.shortName])/$(row[DayCol.shortName])/$(row[YearCol.shortName]) $(row[HourCol.shortName]):$(row[MinCol.shortName])"
        dateTime = Dates.DateTime(dateTime, "mm/dd/yyyy HH:MM")
        push!(dateTimeColumn, [dateTime])
    end
    temporaryDF =  hcat(dateTimeColumn, select(df, Not(1:5)))
    return rename(temporaryDF, [:temporaryName => dt_h.shortName])
end

function changeDateFormatToOriginal(df)
    #=
    changeDateFormatToOriginal changes the given DataFrame object from the single column DateTime format, 
    to the original seperated time unit columns format that the buoy data is downloaded in.

    PARAMETERS:
    df: This is the DataFrame object that will be reformatted

    RETURNS:
    temporaryDF: A DataFrame object with the same data as the given df, but has the DateTime object split into a 
    seperate column for years, months, days, hours, and minutes
    =#
    yearColumn = DataFrame(temp1 = Int[])
    monthColumn = DataFrame(temp2 = Int[])
    dayColumn = DataFrame(temp3 = Int[])
    hourColumn = DataFrame(temp4 = Int[])
    minuteColumn = DataFrame(temp5 = Int[])
    for row in eachrow(df)
        currDate = row[dt_h.shortName]
        push!(yearColumn, [Dates.year(currDate)])
        push!(monthColumn, [Dates.month(currDate)])
        push!(dayColumn, [Dates.day(currDate)])
        push!(hourColumn, [Dates.hour(currDate)])
        push!(minuteColumn, [Dates.minute(currDate)])
    end
    temporaryDF = hcat(yearColumn, monthColumn, dayColumn, hourColumn, minuteColumn, select(df, Not(1)))
    rename!(temporaryDF, [:temp1 => YearCol.shortName, :temp2 => MonthCol.shortName, :temp3 => DayCol.shortName,
    :temp4 => HourCol.shortName, :temp5 => MinCol.shortName])
    return temporaryDF
end
