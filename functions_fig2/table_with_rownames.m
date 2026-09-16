function tbl = table_with_rownames(tbl, rowNameCol)
    % Converts MATLAB row names into a normal first column so Excel labels are visible.
    if ~istable(tbl)
        tbl = struct2table(tbl);
    end

    if ~isempty(tbl.Properties.RowNames)
        effectNames = string(tbl.Properties.RowNames);
        tbl.Properties.RowNames = {};
        tbl = addvars(tbl, effectNames, 'Before', 1, 'NewVariableNames', rowNameCol);
    end
end