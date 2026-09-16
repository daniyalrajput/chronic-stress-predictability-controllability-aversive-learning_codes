function [r,p,ciL,ciH,r2] = corr_with_ci(x,y)
    if numel(x) >= 3 && std(x) > 0 && std(y) > 0
        [r,p] = corr(x,y,'type','Pearson');
        z = atanh(r);
        se = 1/sqrt(numel(x)-3);
        ciL = tanh(z - 1.96*se);
        ciH = tanh(z + 1.96*se);
        r2 = r^2;
    else
        r = NaN; p = NaN; ciL = NaN; ciH = NaN; r2 = NaN;
    end
end
