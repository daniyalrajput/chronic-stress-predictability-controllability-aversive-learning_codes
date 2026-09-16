function T = round_numeric_table(T, ndec)
    if ~istable(T), return; end
    vn = T.Properties.VariableNames;
    for i = 1:numel(vn)
        if isnumeric(T.(vn{i}))
            T.(vn{i}) = round(T.(vn{i}), ndec);
        end
    end
end