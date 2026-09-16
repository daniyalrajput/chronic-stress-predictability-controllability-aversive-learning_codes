function T = round_numeric_table(T, ndec)
    vars = T.Properties.VariableNames;
    for i = 1:numel(vars)
        if isnumeric(T.(vars{i}))
            T.(vars{i}) = round(T.(vars{i}), ndec);
        end
    end
end