function [F, df1, df2, p] = get_effect_from_between(tbl, effectName)
    F = NaN; df1 = NaN; df2 = NaN; p = NaN;

    rowNames = string(tbl.Properties.RowNames);
    idx = find(rowNames == effectName, 1);

    if isempty(idx)
        return;
    end

    F = get_table_value(tbl, idx, {'F', 'FStat'});
    p = get_table_value(tbl, idx, {'pValue', 'p'});

    df1 = get_table_value(tbl, idx, {'DF', 'DF1', 'NumDF'});
    errIdx = idx + 1;
    if errIdx <= height(tbl)
        df2 = get_table_value(tbl, errIdx, {'DF', 'DF2', 'DenDF'});
    end
end