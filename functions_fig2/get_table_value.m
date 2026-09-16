function val = get_table_value(tbl, rowIdx, possibleNames)
    val = NaN;
    varNames = string(tbl.Properties.VariableNames);

    for i = 1:numel(possibleNames)
        nm = string(possibleNames{i});
        idx = find(varNames == nm, 1);
        if ~isempty(idx)
            tmp = tbl{rowIdx, idx};
            if isnumeric(tmp)
                val = double(tmp);
            else
                val = str2double(string(tmp));
            end
            return;
        end
    end
end
