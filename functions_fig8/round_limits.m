function lims = round_limits(lims, ndec)
    if ndec == 0
        lims = [floor(lims(1)), ceil(lims(2))];
    else
        f = 10^ndec;
        lims = [floor(lims(1)*f)/f, ceil(lims(2)*f)/f];
    end
end