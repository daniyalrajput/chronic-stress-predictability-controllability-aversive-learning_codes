function T = standardize_anova_table(Tin)
    T = Tin;
    if isa(T, 'dataset')
        T = dataset2table(T);
    end
    assert(istable(T), 'ANOVA output is not a table.');

    if ~ismember('Effect', T.Properties.VariableNames)
        rn = T.Properties.RowNames;
        if ~isempty(rn)
            T = addvars(T, string(rn), 'Before', 1, 'NewVariableNames', 'Effect');
            T.Properties.RowNames = {};
        elseif ismember('Term', T.Properties.VariableNames)
            T = renamevars(T, 'Term', 'Effect');
        elseif ismember('Name', T.Properties.VariableNames)
            T = renamevars(T, 'Name', 'Effect');
        else
            T = addvars(T, string((1:height(T))'), 'Before', 1, 'NewVariableNames', 'Effect');
        end
    end
end