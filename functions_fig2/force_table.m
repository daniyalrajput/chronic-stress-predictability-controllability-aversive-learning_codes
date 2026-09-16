function tbl = force_table(x)
    if istable(x)
        tbl = x;
    else
        tbl = struct2table(x);
    end
end