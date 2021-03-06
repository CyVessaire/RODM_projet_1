using JuMP
using CPLEX

# Contains:
# - d: the number of features
# - n: the number of transactions in the training set
# - t: the transactions in the training set (each line is a transaction)
# - transactionClass: class of the transactions
include("../data/haberman_train.dat")

#t = [30 64 1 1;30 62 3 1;30 65 0 2;]
mincovy = 0.05
iterlim = 5
RgenX = 0.1 / n
RgenB = 0.1 / (n * d)
s_x = 1

model = Model(solver = CplexSolver())

@variable(model, 0<=x[i in 1:n]<=1)
@variable(model, b[i in 1:d], Bin)

@objective(model,Max,sum(x[i] for i in 1:n if transactionClass[i]==0) - RgenX * sum(x[i] for i in 1:n) - RgenB * sum(b[i] for i in 1:d))

@constraint(model, coverConstraint, sum(x[i] for i in 1:n) <= s_x)
@constraint(model, [i = 1:n, j = 1:d], x[i] <= 1 + (t[i,j] -1) *b[j])
@constraint(model, [i = 1:n], x[i] >= 1 + sum((t[i,j] -1) * b[j] for j in 1:d))

R = Array{Int}(0)

RuleClass = Array{Int}(0)

for C = [0, 1]
    s = 0
    iter = 1
    s_x = n
    R1 = Array{Int}(0)
    @objective(model,Max,sum(x[i] for i in 1:n if transactionClass[i]==C) - RgenX * sum(x[i] for i in 1:n) - RgenB * sum(b[i] for i in 1:d))
    while(s_x > n * mincovy)
        if iter == 1
            JuMP.setRHS(coverConstraint, s_x)
            solve(model)
            x1 = getvalue(x)
            s = sum(x1[i] for i in 1:n if transactionClass[i]==C)
            iter += 1
        end

        b1 = getvalue(b)
        b1 = round.(Int, b1)

        R1 = vcat(R1, transpose(b1))# a terminer
        append!(RuleClass, C)
        @constraint(model, sum(b[j] for j in 1:d if b1[j] == 0) + sum((1-b[j]) for j in 1:d if b1[j] == 1) >= 1)

        if iter < iterlim
            JuMP.setRHS(coverConstraint, s_x)
            solve(model)
            x1 = getvalue(x)

            if (sum(x1[i] for i in 1:n if transactionClass[i]==C) < s)
                s_x = min(s_x -1, sum(x1[i] for i in 1:n))
                iter = 1
            else
                iter += 1
            end

            iter += 1
        else
            s_x -= 1
            iter = 1
        end
    end
    R = vcat(R, R1)

end

@show R

# Rules_dat = Matrix(Int, size(R[1]), size(R[1,1]))
# for i in 1:size(R[1])
#     for j in 1:size(R,2)
#         Rules_dat[i,j]=R[1,i,j]
#     end
# end

# for i in 1:size(R[2])
#    for j in 1:size(R,2)
#        Rules_dat[i+size(R[1],j]=R[2,i,j]
#    end
# end

fout = open("../res/haberman_rules.dat", "w")
println(fout, "rules = ", R)
println(fout, "ruleClass = ", RuleClass)
