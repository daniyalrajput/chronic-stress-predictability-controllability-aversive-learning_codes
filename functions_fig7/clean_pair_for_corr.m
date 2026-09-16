function [x,y] = clean_pair_for_corr(x,y,apply3sd)
    x = x(:); y = y(:);
    keep = ~isnan(x) & ~isnan(y);
    x = x(keep); y = y(keep);

    if apply3sd && numel(x) >= 3
        mux = mean(x,'omitnan'); sdx = std(x,'omitnan');
        muy = mean(y,'omitnan'); sdy = std(y,'omitnan');

        badx = false(size(x));
        bady = false(size(y));

        if sdx > 0 && ~isnan(sdx), badx = abs(x - mux) > 3*sdx; end
        if sdy > 0 && ~isnan(sdy), bady = abs(y - muy) > 3*sdy; end

        keep = ~(badx | bady);
        x = x(keep); y = y(keep);
    end
end