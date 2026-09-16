function y = apply_3sd_vec(y)
    y = y(:);
    idx = ~isnan(y);
    if nnz(idx) < 3, return; end
    mu = mean(y(idx),'omitnan');
    sd = std(y(idx),'omitnan');
    if sd == 0 || isnan(sd), return; end
    bad = abs(y - mu) > 3*sd;
    y(bad) = NaN;
end