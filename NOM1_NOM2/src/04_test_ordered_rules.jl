using JuMP

include("../res/haberman_ordered_rules.dat")
include("../data/haberman_test.dat")

correct_prediction = 0
nbr_class0 = 0
nbr_class1 = 0
pred_class0 = 0
pred_class1 = 0
correct_pred_class0 = 0
correct_pred_class1 = 0

for i in 1:n
    prediction = 2
    for j in 1:length(ruleClass)
        test = true
        for k in 1:d
            if rules[j,k] == 1
                if t[i,k] != 1
                    test = false
                end
            end
        end
        if test
            prediction = ruleClass[j]
            break
        end
    end

    if prediction == 2
        print(transactionClass[i])
        println(" error , $i")
    elseif prediction == 1
        pred_class1 += 1
    else
        pred_class0 += 1
    end



    if transactionClass[i] == prediction
        if prediction == 1
            correct_pred_class1 += 1
        else
            correct_pred_class0 += 1
        end
        correct_prediction += 1
    end

    if transactionClass[i] == 0
        nbr_class0 += 1
    else
        nbr_class1 += 1
    end

end

println(correct_prediction)

total_recall = correct_prediction/n

println(total_recall)

recall0 = correct_pred_class0 / nbr_class0
recall1 = correct_pred_class1 / nbr_class1

accuracy0 = correct_pred_class0 / pred_class0
accuracy1 = correct_pred_class1 / pred_class1

println("recall class 0 : $recall0")
println("recall class 1 : $recall1")
println("accuracy class 0 : $accuracy0")
println("accuracy class 1 : $accuracy1")
