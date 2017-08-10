function T = quick_cell2table(C)
T = cell2table(C(2:end,:), 'VariableNames', C(1,:));
end