using JuMP
using CPLEX

# Contains:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/haberman.data")

#t = [30 64 1 1;30 62 3 1;30 65 0 2;]
t = readdlm("../data/haberman.data", ',')

Size_testing_set = round(Int,size(t,1)/3)

training_data = falses(Size_testing_set,9+1)
testing_data = falses(size(t,1)-Size_testing_set,9+1)

max_age = maximum(t[:,1])
min_age = minimum(t[:,1])
max_date = maximum(t[:,2])
min_date = minimum(t[:,2])
max_nodule = maximum(t[:,3])
min_nodule = minimum(t[:,3])

# create training_data
for i = 1:Size_testing_set
    training_data[i,1] = (t[i,1] < (max_age-min_age)/3 + min_age)
    training_data[i,2] = ((max_age-min_age)/3 + min_age <= t[i,1] < 2*(max_age-min_age)/3 + min_age)
    training_data[i,3] = (t[i,1] >= 2*(max_age-min_age)/3 + min_age)
    training_data[i,4] = (t[i,2] < (max_date-min_date)/3 + min_date)
    training_data[i,5] = ((max_date-min_date)/3 + min_date <= t[i,2] < 2*(max_date-min_date)/3 + min_date)
    training_data[i,6] = (t[i,2] >= 2*(max_date-min_date)/3 + min_date)
    training_data[i,7] = (t[i,3] < (max_nodule-min_nodule)/3 + min_nodule)
    training_data[i,8] = ((max_nodule-min_nodule)/3 + min_nodule <= t[i,3] < 2*(max_nodule-min_nodule)/3 + min_nodule)
    training_data[i,9] = (t[i,3] >= 2*(max_nodule-min_nodule)/3 + min_nodule)
    training_data[i,10] = (t[i,4]-1)
end

# create testing_data
for i = (Size_testing_set+1):size(t,1)
    testing_data[i-Size_testing_set,1] = (t[i,1] < (max_age-min_age)/3 + min_age)
    testing_data[i-Size_testing_set,2] = ((max_age-min_age)/3 + min_age <= t[i,1] < 2*(max_age-min_age)/3 + min_age)
    testing_data[i-Size_testing_set,3] = (t[i,1] >= 2*(max_age-min_age)/3 + min_age)
    testing_data[i-Size_testing_set,4] = (t[i,2] < (max_date-min_date)/3 + min_date)
    testing_data[i-Size_testing_set,5] = ((max_date-min_date)/3 + min_date <= t[i,2] < 2*(max_date-min_date)/3 + min_date)
    testing_data[i-Size_testing_set,6] = (t[i,2] >= 2*(max_date-min_date)/3 + min_date)
    testing_data[i-Size_testing_set,7] = (t[i,3] < (max_nodule-min_nodule)/3 + min_nodule)
    testing_data[i-Size_testing_set,8] = ((max_nodule-min_nodule)/3 + min_nodule <= t[i,3] < 2*(max_nodule-min_nodule)/3 + min_nodule)
    testing_data[i-Size_testing_set,9] = (t[i,3] >= 2*(max_nodule-min_nodule)/3 + min_nodule)
    testing_data[i-Size_testing_set,10] = (t[i,4]-1)
end

@show training_data

open("../data/haberman_train.data", "w") do io
    writedlm(io, training_data, ',')
end

open("../data/haberman_test.data", "w") do io
    writedlm(io, testing_data, ',')
end
