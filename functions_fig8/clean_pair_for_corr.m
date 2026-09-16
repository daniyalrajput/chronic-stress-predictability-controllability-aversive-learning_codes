function [x,y] = clean_pair_for_corr(x,y,apply3sd)
    keep = ~isnan(x) & ~isnan(y);
    x = x(keep);
    y = y(keep);

    if ~apply3sd || numel(x) < 3
        return;
    end

    if std(x) > 0
        kx = abs(x - mean(x)) <= 3*std(x);
    else
        kx = true(size(x));
    end
    if std(y) > 0
        ky = abs(y - mean(y)) <= 3*std(y);
    else
        ky = true(size(y));
    end

    keep2 = kx & ky;
    x = x(keep2);
    y = y(keep2);
end