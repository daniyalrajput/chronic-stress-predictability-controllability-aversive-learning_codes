%% ========================= LOCAL HELPERS FOR TABLE COMPATIBILITY =========================
function T = ensure_table(x, label)
% Convert common MATLAB tabular outputs to table so writetable can save them.
    if istable(x)
        T = x;
        return;
    end

    if isa(x,'dataset')
        T = dataset2table(x);
        return;
    end

    if isstruct(x)
        T = struct2table(x);
        return;
    end

    if iscell(x)
        T = cell2table(x);
        return;
    end

    error('Expected %s to be tabular, but its class is %s.', label, class(x));
end