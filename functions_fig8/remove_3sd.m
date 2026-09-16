function x = remove_3sd(x)
    x = x(~isnan(x));
    if numel(x) < 3, return; end
    m = mean(x);
    s = std(x);
    if s > 0
        x = x(abs(x-m) <= 3*s);
    end
end
