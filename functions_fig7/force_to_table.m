function T = force_to_table(x)

    if istable(x)
        T = x;
        return;
    end

    if isa(x, 'dataset')
        T = dataset2table(x);
        return;
    end

    if isstruct(x)
        T = struct2table(x);
        return;
    end

    if isnumeric(x)
        T = array2table(x);
        return;
    end

    if iscell(x)
        T = cell2table(x);
        return;
    end

    error('Could not convert ANOVA output of class "%s" to a table.', class(x));
end