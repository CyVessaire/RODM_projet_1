using JuMP
using CPLEX
using StatsBase

# Contains:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/haberman.data")

max_number_features_for_age = 5
max_number_features_for_year = 5
max_number_features_for_nodule = 5

#t = [30 64 1 1;30 62 3 1;30 65 0 2;]
t = readdlm("../data/haberman.data", ',')

Size_testing_set = round(Int,2*size(t,1)/3)

age_map_count = countmap(t[:,1])
year_map_count = countmap(t[:,2])
nodule_map_count = countmap(t[:,3])

#println(age_map_count)
#println(year_map_count)
#println(nodule_map_count)

age_map = collect(age_map_count)
#println(age_map)
sort!(age_map)
#println(age_map)
#println(age_map[1])
#println(age_map[2][2])
year_map = collect(year_map_count)
sort!(year_map)
nodule_map = collect(nodule_map_count)
sort!(nodule_map)

#println(size(year_map,1))

if size(year_map,1) > max_number_features_for_year
    year_value = zeros(max_number_features_for_year-1)
    count_fraction_passed = 0
    count_total_passed = 0
    for i = 1:size(year_map,1)
        count_total_passed += year_map[i][2]
        if count_total_passed > (count_fraction_passed+1)/max_number_features_for_year*size(t,1)
            count_fraction_passed += 1
            year_value[count_fraction_passed] = year_map[i][1]
        elseif size(year_map,1) - i == max_number_features_for_year - 1 - count_fraction_passed - 1
            count_fraction_passed += 1
            year_value[count_fraction_passed] = year_map[i][1]
        end
    end
else
    year_value = zeros(size(year_map,1))
    for i = 1:size(year_map,1)
        year_value[i] = year_map[i][1]
    end
end

if size(nodule_map,1) > max_number_features_for_nodule
    nodule_value = zeros(max_number_features_for_nodule-1)
    count_fraction_passed = 0
    count_total_passed = 0
    for i = 1:size(nodule_map,1)
        count_total_passed += nodule_map[i][2]
        if count_total_passed > (count_fraction_passed+1)/max_number_features_for_nodule*size(t,1)
            count_fraction_passed += 1
            nodule_value[count_fraction_passed] = nodule_map[i][1]
        elseif size(nodule_map,1) - i == max_number_features_for_nodule - 1 - count_fraction_passed - 1
            count_fraction_passed += 1
            nodule_value[count_fraction_passed] = nodule_map[i][1]
        end
    end
else
    nodule_value = zeros(size(nodule_map,1))
    for i = 1:size(nodule_map,1)
        nodule_value[i] = nodule_map[i][1]
    end
end

if size(age_map,1) > max_number_features_for_age
    age_value = zeros(max_number_features_for_age-1)
    count_fraction_passed = 0
    count_total_passed = 0
    for i = 1:size(age_map,1)
        count_total_passed += age_map[i][2]
        if count_total_passed > (count_fraction_passed+1)/max_number_features_for_age*size(t,1)
            count_fraction_passed += 1
            age_value[count_fraction_passed] = age_map[i][1]
        elseif size(age_map,1) - i == max_number_features_for_age - 1 - count_fraction_passed - 1
            count_fraction_passed += 1
            age_value[count_fraction_passed] = age_map[i][1]
        end
    end
else
    age_value = zeros(size(age_map,1))
    for i = 1:size(age_map,1)
        age_value[i] = age_map[i][1]
    end
end

#println(year_map)
#println(year_value)
#println(nodule_map)
#println(nodule_value)
#println(age_map)
#println(age_value)

t = t[shuffle(1:end), :]

training_data = zeros(Int,Size_testing_set,size(year_value,1)+size(nodule_value,1)+size(age_value,1)+1)
testing_data = zeros(Int,size(t,1)-size(training_data,1),size(training_data,2))


#max_age = maximum(t[:,1])
#min_age = minimum(t[:,1])
#max_date = maximum(t[:,2])
#min_date = minimum(t[:,2])
#max_nodule = maximum(t[:,3])
#min_nodule = minimum(t[:,3])

# create training_data
for i = 1:Size_testing_set
    s = 0
    for j = 1:size(age_value,1)
        if t[i,1] >= age_value[j]
            s = j
        end
    end
    training_data[i,s+1] = 1

    s = 0
    for j = 1:size(year_value,1)
        if t[i,2] >= year_value[j]
            s = j
        end
    end

    training_data[i,size(age_value,1)+s+1] = 1

    s = 0
    for j = 1:size(nodule_value,1)
        if t[i,3] >= nodule_value[j]
            s = j
        end
    end

    training_data[i,size(age_value,1)+size(year_value,1)+s+1] = 1

    training_data[i,size(training_data,2)] = (t[i,4]-1)
end

# create testing_data
for i = (Size_testing_set+1):size(t,1)
    s = 0
    for j = 1:size(age_value,1)
        if t[i,1] >= age_value[j]
            s = j
        end
    end
    testing_data[i-Size_testing_set,s+1] = 1

    s = 0
    for j = 1:size(year_value,1)
        if t[i,2] >= year_value[j]
            s = j
        end
    end

    testing_data[i-Size_testing_set,size(age_value,1)+s+1] = 1

    s = 0
    for j = 1:size(nodule_value,1)
        if t[i,3] >= nodule_value[j]
            s = j
        end
    end

    testing_data[i-Size_testing_set,size(age_value,1)+size(year_value,1)+s+1] = 1

    testing_data[i-Size_testing_set,size(testing_data,2)] = (t[i,4]-1)
end

#@show training_data

d = size(training_data, 2)-1
n = size(training_data, 1)
t = training_data[:,1:end-1]
transactionClass = transpose(training_data[:,end])

fout = open("../data/haberman_train.dat", "w")
println(fout, "d = ", d)
println(fout, "n = ", n)
println(fout, "t = ", t)
println(fout, "transactionClass = ", transactionClass)

d = size(testing_data, 2)-1
n = size(testing_data, 1)
t = testing_data[:,1:end-1]
transactionClass = transpose(testing_data[:,end])

fout = open("../data/haberman_test.dat", "w")
println(fout, "d = ", d)
println(fout, "n = ", n)
println(fout, "t = ", t)
println(fout, "transactionClass = ", transactionClass)
