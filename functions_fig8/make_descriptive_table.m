function Desc = make_descriptive_table(T)
    G = findgroups(T.Group, T.Control, T.Predictability);
    grp = splitapply(@(x) {string(x(1))}, T.Group, G);
    ctl = splitapply(@(x) {string(x(1))}, T.Control, G);
    prd = splitapply(@(x) {string(x(1))}, T.Predictability, G);
    n   = splitapply(@(x) sum(~isnan(x)), T.Value, G);
    mu  = splitapply(@(x) mean(x,'omitnan'), T.Value, G);
    sd  = splitapply(@(x) std(x,'omitnan'), T.Value, G);
    sem = sd ./ sqrt(n);

    Desc = table(string([grp{:}])', string([ctl{:}])', string([prd{:}])', n, mu, sd, sem, ...
        'VariableNames', {'Group','Control','Predictability','N','Mean','SD','SEM'});
end
