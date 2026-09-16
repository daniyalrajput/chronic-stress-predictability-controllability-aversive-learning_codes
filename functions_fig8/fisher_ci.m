function [ciL, ciH] = fisher_ci(r, n)
    if isnan(r) || n <= 3 || abs(r) >= 1
        ciL = NaN; ciH = NaN; return;
    end
    z = atanh(r);
    se = 1/sqrt(n-3);
    zL = z - 1.96*se;
    zH = z + 1.96*se;
    ciL = tanh(zL);
    ciH = tanh(zH);
end