function lim = padded_limits(v)
    v = v(~isnan(v));
    if isempty(v)
        lim = [0 1];
        return;
    end
    lo = min(v);
    hi = max(v);
    if lo == hi
        pad = max(abs(lo)*0.05, 1);
        lim = [lo-pad, hi+pad];
    else
        pad = 0.08 * (hi-lo);
        lim = [lo-pad, hi+pad];
    end
end