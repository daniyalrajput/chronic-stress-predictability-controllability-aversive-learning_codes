function v = apply_3sd_vec(v)
    v = v(:);
    idx = ~isnan(v);
    x = v(idx);
    if numel(x) < 3 || std(x) == 0
        return;
    end
    m = mean(x);
    s = std(x);
    keep = abs(x - m) <= 3*s;
    ii = find(idx);
    v(ii(~keep)) = NaN;
end