using JuMP
using CPLEX

# Contains:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/haberman_train.data")

#t = [30 64 1 1;30 62 3 1;30 65 0 2;]
training_data = readdlm("../data/haberman_train.data", ',', Bool)

@show training_data

n = size(training_data,1)
d = size(training_data,2)-1
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
