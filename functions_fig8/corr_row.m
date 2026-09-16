function row = corr_row(x, y, groupLabel, sessionLabel, outcomeLabel, apply3sd)
    x = x(:);
    y = y(:);
    ok = ~isnan(x) & ~isnan(y);
    x = x(ok);
    y = y(ok);

    if apply3sd && numel(y) >= 3
        m = mean(y); s = std(y);
        if s > 0
            keep = abs(y-m) <= 3*s;
            x = x(keep);
            y = y(keep);
        end
    end

    n = numel(x);

    if n >= 3 && std(x) > 0 && std(y) > 0
        [r,p] = corr(x, y, 'Type','Pearson');
        [ciL, ciH] = fisher_ci(r, n);
        r2 = r^2;
    else
        r = NaN; p = NaN; ciL = NaN; ciH = NaN; r2 = NaN;
    end

    row = {groupLabel, sessionLabel, outcomeLabel, n, r, p, ciL, ciH, r2, mean(x,'omitnan'), mean(y,'omitnan')};
end