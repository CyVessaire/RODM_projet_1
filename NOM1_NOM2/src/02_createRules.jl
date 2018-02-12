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
    writedlm(io, training_data)
end

open("../data/haberman_test.data", "w") do io
    writedlm(io, testing_data)
end

n = size(training_data,1)
d=size(training_data,2)-1
mincovy = 0.05
iterlim = 5
RgenX = 0.1 / n
RgenB = 0.1 / (n * d)
s_x = 1

model = Model(solver = CplexSolver())

@variable(model, 0<=x[i in 1:n]<=1)
@variable(model, b[i in 1:d], Bin)

@objective(model,Max,sum(x[i] for i in 1:n if training_data[i,d+1]==0) + RgenX * sum(x[i] for i in 1:n) - RgenB * sum(b[i] for i in 1:d))

@constraint(model, coverConstraint, sum(x[i] for i in 1:n) <= s_x)
@constraint(model, [i = 1:n, j = 1:d], x[i] <= 1 + (training_data[i,j] -1) *b[j])
@constraint(model, [i = 1:n], x[i] >= 1 + sum((training_data[i,j] -1) * b[j] for j in 1:d))
@constraint(model, sum(x[i] for i in 1:n) <= s_x)
@constraint(model, sum(x[i] for i in 1:n) <= s_x)

R=[]

for C = [false, true]
    s = 0
    iter = 1
    s_x = n
    R1 = []
    while(s_x > n * mincovy)
        @objective(model,Max,sum(x[i] for i in 1:n if training_data[i,d+1]==C) + RgenX * sum(x[i] for i in 1:n) - RgenB * sum(b[i] for i in 1:d))
        JuMP.setRHS(coverConstraint, s_x)
        if iter == 1
            solve(model)
            x1 = getvalue(x)
            s = sum(x1[i] for i in 1:n)
            b1 = getvalue(b)
            iter += 1
        end
        append!(R1,b1) # a terminer
        @constraint(model, sum(b[j] for j in 1:d if b1[j] == 0) + sum((1-b[j]) for j in 1:d if b1[j] == 1) >= 1)

        if iter < iterlim
            solve(model)
            x1 = getvalue(x)
            if (sum(x1[i] for i in 1:n) < s)
                s_x = min(s_x -1, sum(x1[i] for i in 1:n))
                iter = 1
            else
                iter += 1
            end
            b1 = getvalue(b)
            iter += 1
        else
            s_x -= 1
            iter = 1
        end
    end
    append!(R,R1)
end

@show R
