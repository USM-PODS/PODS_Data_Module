using DataFrames
using CSV
using Query
using Dates

function findPercentile(df, column, percentile)
    #=
    findPercentile is a function which takes in a DataFrame object, and one of the DataFrames columns, as well as a percentile value as a 
    number. 

    PARAMETERS:
    df: THe DataFrame which contains the column
    column: The column of which you wish to find the percentile
    percentile: The target percentile to find the value of

    RETURNS:
    sortedColumn[indexOfPercentile]: This is a number which is the lowest value within the given percentile of the given column
    =#
    sortedColumn = sort(df[:,column.shortname])
    indexOfPercentile = Int(round((percentile/100)* size(df)[1]))
    return sortedColumn[indexOfPercentile]
end

function findPercentile(df, column, percentile, printOut)
    #=
    findPercentile is a function which takes in a DataFrame object, and one of the DataFrames columns, as well as a percentile value as a 
    number. 

    PARAMETERS:
    df: THe DataFrame which contains the column
    column: The column of which you wish to find the percentile
    percentile: The target percentile to find the value of
    printOut: If true, prints out a statement summarizing the value found.

    RETURNS:
    sortedColumn[indexOfPercentile]: This is a number which is the lowest value within the given percentile of the given column
    =#
    sortedColumn = sort(df[!,column.shortname])
    indexOfPercentile = Int(round((percentile/100)* size(df)[1]))
    #Prints statement so you can see the exact percentile found: percentile will almost never be a nice
    #round number.
    if(printOut)
        println("Found value ", df[!, column.shortname][indexOfPercentile], " is the ", percentile, " percentile.")
    end
    return sortedColumn[indexOfPercentile]
end

function filterDataFrame(dataFrame, column, lowerBound, upperBound)
    #=
    filterDataFrame is a function which takes in a data frame, and returns a new data frame which is filtered.
    It filters the data and only returns the rows in which the value in the selected column(columnName) is in between, or equal to, the lowerBound and upperBound.

    PARAMETERS:
    dataFrame: The DataFrame object which is to be filtered.
    columName: The column which the filter will be applied to 
    lowerBound: The lowest value that will be stored in the new DataFrame
    upperBound: The highest value that will be stored in the new DataFrame

    RETURNS:
    filteredDF: A new DataFrame, containing each row from the original dataFrame whose contents in the selected column meet the filtering conditions.
    =#
    #We have to rename the selected column temporarily to a default name to make the @filter command work.
    workingDF = copy(dataFrame)
    rename!(workingDF,[column.shortname => :FilterColumn])
    filteredDF =  workingDF |> @filter(_.FilterColumn >= lowerBound && _.FilterColumn <= upperBound) |> DataFrame
    rename!(filteredDF,[:FilterColumn => column.shortname])
    return filteredDF
end

function averageByHour(df)
    #=
    averageByHour is a function which takes in a DataFrame, specifically one formatted with standard 
    PODS buoy headers, and returns a new DataFrame which has the same format. The DataFrame being returned
    will have the same data as the parameter, but every data value from the same hour will be averaged together
    with the rest of the values from the same column and hour (excluding error values, which do not contribute to the average).
    The result of this is a DataFrame which contains the hourly average value for each column .

    PARAMETERS:
    df: The DataFrame object which contains the original data. Must be in the standard PODS buoy DataFrame format. 

    RETURNS:
    createdDF: A DataFrame with the same format as parameter df, contains rows seperated by each hour, with each column
    of each row being the averaged value of every valid reading collected in that hour. Has the standard 99 and 999 error values,
    for when no valid readings were taken in the hour.
    =#

    #This line copies the format of the original DataFrame df by setting the createdDF equal to it, but indexing 
    #none of the values in df. Not() is a command which means return everything but, and the : is used to index all rows. So, 
    #We are taking no rows from the df and setting createdDF equal to that. 
    createdDF = df[Not(:), :]
    #Here I use for loops to iterate throught the data, selecting a smaller subset of the data with each for loop. 
    #We use the @filter command from Query to make a new DataFrame that only contains a certain section of the data each time. 
    #We start with selecting a specific years data from the complete df, 
    for year in unique(df, :yr)[:, :yr]
        yearlyDF = df |> @filter(_.yr == year) |> DataFrame
        #Then select each month from the current year, using the DataFrame yearlyDF so we only get the monthly data of
        #the year we are observing.
        for month in unique(yearlyDF, :mo)[:, :mo]
            monthlyDF = yearlyDF |> @filter(_.mo == month) |> DataFrame
            #We repeat this process to select each day in the current month, 
            for day in unique(monthlyDF, :day)[:, :day]
                dailyDF = monthlyDF |> @filter(_.day == day) |> DataFrame
                #and finally repeat the process once more to find each hour of that day, reaching the scope at which
                #we wish to average together each rows values. 
                for hour in unique(dailyDF, :hr)[:, :hr]
                    hourlyDF = dailyDF |> @filter(_.hr == hour) |> DataFrame
                    #Check to see if we need to average anything, if there is only one row then there is no reason to average!
                    if(nrow(hourlyDF) > 1)
                        #statisticsArray is the array which we will add each average to, and then later we will
                        #add this array to the new createdDF as the row values for the hour. 
                        statisticsArray = zeros(18)
                        #For loop to iterate through each column of the hourlyDF, ncol() returns the number of columns in the given
                        #DataFrame.
                        for col in range(1, ncol(hourlyDF), ncol(hourlyDF))
                            #We have to cast col to an integer, since range() returns a float value, 
                            #And we need to use col for indexing. 
                            col = Int(col)
                            #nrow() is the same as ncol(), we need to keep track of the number of rows counted to calculate the average, so we
                            #use colRowTot. This is because if there is an error value, we need to know not to count that in the calculation
                            #of the average, whether that be as a summed value or the integer number of rows counted.
                            colRowTot = nrow(hourlyDF)
                            #temporaryColumnTotal is the sum of all the row values we are included in the sum in the calculation of our average.
                            temporaryColumnTotal = 0
                            #errorVal is the error value of the current column. We refer back to the array of Column objects that we use for formatting;
                            #we index the array of Column objects to get our current columns corresponding object, then access that objects error value.
                            errorVal = DefaultColumns[col].errValue
                            #Next we iterate through each row, eachrow() gives us an iterable object we can loop through. 
                            #row is the current row from hourlyDF.
                            for row in eachrow(hourlyDF)
                                #Check if row[col] is the error value. If it is, we don't want to include it in the colRowTot, as we use that
                                #to determine the average. So, we subtract 1 from the colRowTot because we know we are not using one value.
                                if row[col] == errorVal
                                    colRowTot -= 1
                                else
                                    #If row[col] is not the error value, we add it to temporaryColumnTotal
                                    temporaryColumnTotal += row[col]
                                end
                            end
                            #colRowTot should only be less than 1 if there are only error values in the current hourlyDF. 
                            #Therefore, we should have the average be the error value, there isn't any usable data. 
                            if colRowTot < 1
                                statisticsArray[col] = errorVal
                            else
                                #This checks the element type of the current column, 
                                #If the element type is Integer we need to round the average. 
                                #Regardless of the element type, we do the average calculation using temporaryColumnTotal and colRowTot,
                                #and we finally have the daily average value for this column! We add it to statisticsArray at this 
                                #columns index to be pushed to the createdDF.
                                if(eltype(hourlyDF[:, col]) == Int64)
                                    statisticsArray[col] = Int64(round(temporaryColumnTotal / colRowTot))
                                else
                                    statisticsArray[col] = temporaryColumnTotal/colRowTot
                                end
                            end
                        end
                        #Outside of the for loop for each column in hourlyDF, we finally push our new array of averages to 
                        #the createdDF and then move onto the next hour.
                        push!(createdDF, statisticsArray)
                    #Else statement for the scenario when there is only 1 row in hourlyDF
                    else
                        push!(createdDF, hourlyDF[1, :])
                    end
                end
            end
        end
    end
    return createdDF
end

function averageByDay(df, calculateOutliers = false)
    #=
    averageByHour is a function which takes in a DataFrame, specifically one formatted with standard 
    PODS buoy headers, and returns a new DataFrame which has the same format. The DataFrame being returned
    will have the same data as the parameter, but every data value from the same day will be averaged together
    with the rest of the values from the same column and data (excluding error values, which do not contribute to the average).
    The result of this is a DataFrame which contains the daily average value for each column .

    PARAMETERS:
    df: The DataFrame object which contains the original data. Must be in the standard PODS buoy DataFrame format. 

    RETURNS:
    createdDF: A DataFrame with the same format as parameter df, contains rows seperated by each day, with each column
    of each row being the averaged value of every valid reading collected in that day. Has the standard 99 and 999 error values,
    for when no valid readings were taken in the day.
    =#

    #This line copies the format of the original DataFrame df by setting the createdDF equal to it, but indexing 
    #none of the values in df. Not() is a command which means return everything but, and the : is used to index all rows. So, 
    #We are taking no rows from the df and setting createdDF equal to that. 
    createdDF = df[Not(:), :]
    #Here I use for loops to iterate throught the data, selecting a smaller subset of the data with each for loop. 
    #We use the @filter command from Query to make a new DataFrame that only contains a certain section of the data each time. 
    #We start with selecting a specific years data from the complete df, 
    for year in unique(df, :yr)[:, :yr]
        yearlyDF = df |> @filter(_.yr == year) |> DataFrame
        #Then select each month from the current year, using the DataFrame yearlyDF so we only get the monthly data of
        #the year we are observing.
        for month in unique(yearlyDF, :mo)[:, :mo]
            monthlyDF = yearlyDF |> @filter(_.mo == month) |> DataFrame
            #We repeat this process to select each day in the current month, reaching the scope at which we want
            #to average together each row's values together.
            for day in unique(monthlyDF, :day)[:, :day]
                dailyDF = monthlyDF |> @filter(_.day == day) |> DataFrame
                #Check to see if we need to average anything, if there is only one row then there is no reason to average!
                if(nrow(dailyDF) > 1)
                    #statisticsArray is the array which we will add each average to, and then later we will
                    #add this array to the new createdDF as the row values for the day. 
                    statisticsArray = zeros(ncol(dailyDF))
                    #For loop to iterate through each column of the dailyDF, ncol() returns the number of columns in the given
                    #DataFrame.
                    for col in range(1, ncol(dailyDF), ncol(dailyDF))
                        #We have to cast col to an integer, since range() returns a float value, 
                        #And we need to use col for indexing. 
                        col = Int(col)
                        #nrow() is the same as ncol(), we need to keep track of the number of rows counted to calculate the average, so we
                        #use colRowTot. This is because if there is an error value, we need to know not to count that in the calculation
                        #of the average, whether that be as a summed value or the integer number of rows counted.
                        colRowTot = nrow(dailyDF)
                        #temporaryColumnTotal is the sum of all the row values we are included in the sum in the calculation of our average.
                        temporaryColumnTotal = 0
                        #errorVal is the error value of the current column. We refer back to the array of Column objects that we use for formatting;
                        #we index the array of Column objects to get our current columns corresponding object, then access that objects error value.
                        errorVal = DefaultColumns[col].errValue
                        #Next we iterate through each row, eachrow() gives us an iterable object we can loop through. 
                        #row is the current row from monthlyDF.
                        for row in eachrow(dailyDF)
                            #Check if row[col] is the error value. If it is, we don't want to include it in the colRowTot, as we use that
                            #to determine the average. So, we subtract 1 from the colRowTot because we know we are not using one value.
                            if row[col] == errorVal
                                colRowTot -= 1
                            else
                                #If row[col] is not the error value, we add it to temporaryColumnTotal
                                temporaryColumnTotal += row[col]
                            end 
                        end
                        #colRowTot should only be less than 1 if there are only error values in the current dailyDF. 
                        #Therefore, we should have the average be the error value, there isn't any usable data. 
                        if colRowTot < 1
                            statisticsArray[col] = errorVal
                        else
                        #This checks the element type of the current column, 
                        #If the element type is Integer we need to round the average. 
                        #Regardless of the element type, we do the average calculation using temporaryColumnTotal and colRowTot,
                        #and we finally have the daily average value for this column! We add it to statisticsArray at this 
                        #columns index to be pushed to the createdDF.
                            if(eltype(dailyDF[:, col]) == Int64)
                                statisticsArray[col] = Int64(round(temporaryColumnTotal / colRowTot))
                            else
                                statisticsArray[col] = temporaryColumnTotal/colRowTot
                            end
                        end
                    end
                    #Outside of the for loop for each column in dailyDF, we finally push our new array of averages to 
                    #the createdDF and then move onto the next day.
                    push!(createdDF, statisticsArray)
                #Else statement for the scenario when there is only 1 row in monthlyDF
                else
                    push!(createdDF, dailyDF[1, :])
                end
            end
        end
    end
    return createdDF
end

function averageByMonth(df)
    #=
    averageByHour is a function which takes in a DataFrame, specifically one formatted with standard 
    PODS buoy headers, and returns a new DataFrame which has the same format. The DataFrame being returned
    will have the same data as the parameter, but every data value from the same month will be averaged together
    with the rest of the values from the same column and data (excluding error values, which do not contribute to the average).
    The result of this is a DataFrame which contains the monthly average value for each column .

    PARAMETERS:
    df: The DataFrame object which contains the original data. Must be in the standard PODS buoy DataFrame format. 

    RETURNS:
    createdDF: A DataFrame with the same format as parameter df, contains rows seperated by each day, with each column
    of each row being the averaged value of every valid reading collected in that month. Has the standard 99 and 999 error values,
    for when no valid readings were taken in the month.
    =#

    #This line copies the format of the original DataFrame df by setting the createdDF equal to it, but indexing 
    #none of the values in df. Not() is a command which means return everything but, and the : is used to index all rows. So, 
    #We are taking no rows from the df and setting createdDF equal to that. 
    createdDF = df[Not(:), :]
    outlierDF = createdDF
    #Here I use for loops to iterate throught the data, selecting a smaller subset of the data with each for loop. 
    #We use the @filter command from Query to make a new DataFrame that only contains a certain section of the data each time. 
    #We start with selecting a specific years data from the complete df, 
    for year in unique(df, :yr)[:, :yr]
        yearlyDF = df |> @filter(_.yr == year) |> DataFrame
        #Then select each month from the current year, using the DataFrame yearlyDF so we only get the monthly data of
        #the year we are observing.  This is the final scope at which we wish to average together the data for each column,
        #from each row.
        for month in unique(yearlyDF, :mo)[:, :mo]
            monthlyDF = yearlyDF |> @filter(_.mo == month) |> DataFrame
            #Check to see if we need to average anything, if there is only one row then there is no reason to average!
            if(nrow(monthlyDF) > 1)
                #statisticsArray is the array which we will add each average to, and then later we will
                #add this array to the new createdDF as the row values for the month. 
                statisticsArray = zeros(18)
                #For loop to iterate through each column of the monthlyDF, ncol() returns the number of columns in the given
                #DataFrame.
                for col in range(1, ncol(monthlyDF), ncol(monthlyDF))
                    #We have to cast col to an integer, since range() returns a float value, 
                    #And we need to use col for indexing. 
                    col = Int(col)
                    #nrow() is the same as ncol(), we need to keep track of the number of rows counted to calculate the average, so we
                    #use colRowTot. This is because if there is an error value, we need to know not to count that in the calculation
                    #of the average, whether that be as a summed value or the integer number of rows counted.
                    colRowTot = nrow(monthlyDF)
                    #temporaryColumnTotal is the sum of all the row values we are included in the sum in the calculation of our average.
                    temporaryColumnTotal = 0
                    #errorVal is the error value of the current column. We refer back to the array of Column objects that we use for formatting;
                    #we index the array of Column objects to get our current columns corresponding object, then access that objects error value.
                    errorVal = DefaultColumns[col].errValue
                    #Next we iterate through each row, eachrow() gives us an iterable object we can loop through. 
                    #row is the current row from monthlyDF.
                    for row in eachrow(monthlyDF)
                        #Check if row[col] is the error value. If it is, we don't want to include it in the colRowTot, as we use that
                        #to determine the average. So, we subtract 1 from the colRowTot because we know we are not using one value.
                        if row[col] == errorVal
                            colRowTot -= 1
                        else
                            #If row[col] is not the error value, we add it to temporaryColumnTotal
                            temporaryColumnTotal += row[col]
                        end
                    end
                    #colRowTot should only be less than 1 if there are only error values in the current monthlyDF. 
                    #Therefore, we should have the average be the error value, there isn't any usable data. 
                    if colRowTot < 1
                        statisticsArray[col] = errorVal
                    else
                        #This checks the element type of the current column, 
                        #If the element type is Integer we need to round the average. 
                        #Regardless of the element type, we do the average calculation using temporaryColumnTotal and colRowTot,
                        #and we finally have the monthly average value for this column! We add it to statisticsArray at this 
                        #columns index to be pushed to the createdDF.
                        if(eltype(monthlyDF[:, col]) == Int64)
                            statisticsArray[col] = Int64(round(temporaryColumnTotal / colRowTot))
                        else
                            statisticsArray[col] = temporaryColumnTotal/colRowTot
                        end
                    end
                end
                #Outside of the for loop for each column in monthlyDF, we finally push our new array of averages to 
                #the createdDF and then move onto the next month.
                push!(createdDF, statisticsArray)
            #Else statement for the scenario when there is only 1 row in monthlyDF
            else
                push!(createdDF, monthlyDF[1, :])
            end
        end
    end
    return createdDF
end


#Need to update this for an error array
function filterMissing(df, column)
    #=
    filterMissing is a function which filters the given DataFrame, and returns a new DataFrame which is all of the rows
    which do not have a missing value in the given column.
    
    PARAMETERS:
    df: The DataFrame object to filter
    column: The column whose missing values will be filtered out

    RETURNS:
    filteredDF: A DataFrame which contains only the rows from the df which have measurements in the given column.
    =#
    
    #Creating a copy of the given DataFrame df so that we don't accidentally modify the df
    temporaryDF = copy(df)
    #Grabs the error value of the given column
    errorValue = column.errValue
    #Renaming the column we wish to filter, as the iterator in the @filter command is very picky about the column selection.
    #We need to give it a specific column, so to generalize this I set whatever column we are filtering to FilterColumn, 
    #And change it back after the filtering command.
    rename!(temporaryDF,[column.shortname => :FilterColumn])
    filteredDF =  temporaryDF |> @filter(_.FilterColumn != errorValue) |> DataFrame
    rename!(filteredDF,[:FilterColumn => column.shortname])
    return filteredDF
end