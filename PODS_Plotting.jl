using Plots
using StatsPlots
using StatsBase
using DataFrames
using CSV
using Dates

function quickHistogram(df, column)
    #=
    quickHistogram is a function which throws together a simple histogram of whatever DataFrame and Column you give it. 
    
    PARAMETERS:
    df: The DataFrame which contains the column data
    column: The Column object to search df for the values

    RETURNS:
    Returns a histogram plot object.
    =#
    #Creating a copy of our DataFrame so we don't accidentially edit it
    workingDF = copy(df)
    #Filter the missing values from the working DataFrame's selected column.
    workingDF = filterMissing(workingDF, column)
    #This sets the xaxis title using the field formalName  in the Column object.
    xAxisTitle = column.formalName
    #The histogram plot object is constructed in the return statement. 
    if isempty(workingDF)
        return plot()
    else
        return Plots.histogram(workingDF[:, column.shortname], xlabel = xAxisTitle, bins = column.defaultBins)
    end
end

function quickHistogram(df, column, customBins)
    #=
    quickHistogram is a function which throws together a simple histogram of whatever DataFrame and Column you give it. 
    
    PARAMETERS:
    df: The DataFrame which contains the column data
    column: The Column object to search df for the values
    customBins: An optional parameter which sets the bins for the histogram

    RETURNS:
    Returns a histogram plot object.
    =#
    #Creating a copy of our DataFrame so we don't accidentially edit it
    workingDF = copy(df)
    #Filter the missing values from the working DataFrame's selected column.
    workingDF = filterMissing(workingDF, column)
    #This sets the xaxis title using the field formalName  in the Column object.
    xAxisTitle = column.formalName
    #The histogram plot object is constructed in the return statement. 
    if isempty(workingDF)
        return plot()
    else
        return Plots.histogram(workingDF[:, column.shortname], xlabel = xAxisTitle, bins = customBins, xticks = customBins)
    end
end
function compareFrequencyPlots(df1, df2, column, labels)
    #=
    compareFrequencyPlots is a quick way to compare two DataFrames by seeing the frequency plots of each in a given column.
    
    PARAMETERS:
    df1: The first DataFrame
    df2: The second DataFrame
    column: The column to compare the two DataFrames
    labels: A list of strings that is the label desired for each DataFrame,
    df1 label is the first string in labels, and the second string in labels is the label for df2.

    RETURNS:
    newHistogramPlot: The created histogram plot object
    =#
    df1e = filterMissing(df1, column)
    df2e =  filterMissing(df2, column)
    newHistogramPlot = histogram(df1e[:, column.shortname], bins = column.defaultBins, label = labels[1], alpha = 0.8, 
    title = column.formalName * " in " * labels[1] * " and " * labels[2], xlabel = column.formalName * " (" * column.units * ")", ylabel = "Measurements")
    histogram!(newHistogramPlot, df2e[:, column.shortname], bins = column.defaultBins, alpha = 0.8, label = labels[2])
    return newHistogramPlot
end

function graphAllFrequencyPlots(df, stringLabelOfDataFrame)
    #=
    graphAllFrequencyPlots is a function which throws together histogram plots for every column of data in 
    a given DataFrame. Used primarirly to investigate the validity of the data, and shape of the data in each column.

    PARAMETERS:
    df: The DataFrame which you want tohe frequency plots of.
    yearOfDataString: A string which is the label for the DataFrame.

    RETURNS: 
    
    
    =#
    graphsMade = []
    for currCol in DefaultColumns
        push!(graphsMade, quickHistogram(df, currCol))
    end
    createdGraph = Plots.plot(graphsMade...)
    plot!(createdGraph, size = (3000,3000), legend = false, title = stringLabelOfDataFrame)
    return createdGraph
end

function createABoxPlot(df, xColumn, yColumn)
    #=
    createABoxPlot is a function which constructs a simple boxplot from the given DataFrame, and given x and y column.
    In my experience, it is best for buoy data to put a time column as the xColumn.

    PARAMETERS:
    df: A DataFrame object where the data to graph is.
    xColumn: The Column to get the X axis data from
    yColumn: The Column to get the Y axis data from

    RETURNS:
    Returns a boxplot object with the data plotted.

    =#
    titleString = xColumn.formalName * " vs " * yColumn.formalName
    titleString = titleString
    xAxisTitle = xColumn.formalName
    yAxisTitle = yColumn.formalName
    xData = df[!, xColumn.shortname]
    yData = df[!, yColumn.shortname]
    return boxplot(xData, yData, title = titleString, ylabel = yAxisTitle,  xlabel = xAxisTitle)
end