function lim = round_limits(lim, ndec)
    p = 10^ndec;
    lim = [floor(lim(1)*p)/p, ceil(lim(2)*p)/p];
end