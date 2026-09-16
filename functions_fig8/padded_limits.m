function lims = padded_limits(v)
    v = v(:); v = v(~isnan(v));
    if isempty(v)
        lims = [0 1];
        return;
    end
    lo = min(v); hi = max(v);
    if lo == hi
        pad = max(abs(lo)*0.05, 1);
    else
        pad = 0.05*(hi-lo);
    end
    lims = [lo-pad, hi+pad];
end