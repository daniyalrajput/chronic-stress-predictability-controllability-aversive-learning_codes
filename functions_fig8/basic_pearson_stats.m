function [r, p, ci_low, ci_high, r2, n] = basic_pearson_stats(x, y)

    x = x(:);
    y = y(:);

    keep = ~isnan(x) & ~isnan(y);
    x = x(keep);
    y = y(keep);

    n = numel(x);

    if n < 3
        r = NaN; p = NaN; ci_low = NaN; ci_high = NaN; r2 = NaN;
        return;
    end

    [r, p] = corr(x, y, 'type', 'Pearson');

    z = atanh(r);
    se = 1 / sqrt(n - 3);
    z_ci = z + [-1.96 1.96] * se;
    r_ci = tanh(z_ci);

    ci_low  = r_ci(1);
    ci_high = r_ci(2);
    r2 = r^2;
end