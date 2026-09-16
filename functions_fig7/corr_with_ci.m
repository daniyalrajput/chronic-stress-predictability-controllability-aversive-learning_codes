function [r,p,ciL,ciH,r2] = corr_with_ci(x,y)
    x = x(:); y = y(:);

    if numel(x) < 3 || std(x)==0 || std(y)==0
        r = NaN; p = NaN; ciL = NaN; ciH = NaN; r2 = NaN;
        return;
    end

    [R,P] = corrcoef(x,y,'Rows','complete');
    r = R(1,2);
    p = P(1,2);
    r2 = r^2;

    n = numel(x);
    z = atanh(r);
    se = 1/sqrt(n-3);
    zcrit = 1.96;
    ci = tanh([z - zcrit*se, z + zcrit*se]);
    ciL = ci(1);
    ciH = ci(2);
end