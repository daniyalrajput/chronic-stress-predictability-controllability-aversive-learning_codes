function [xlim_use, ylim_use] = auto_axis_limits(x, y1, y2)

    allX = x(:);
    allY = [y1(:); y2(:)];

    allX = allX(~isnan(allX));
    allY = allY(~isnan(allY));

    if isempty(allX)
        xlim_use = [0 1];
    else
        xmin = min(allX);
        xmax = max(allX);
        if xmin == xmax
            xmin = xmin - 1;
            xmax = xmax + 1;
        end
        pad = 0.05 * (xmax - xmin);
        xlim_use = [xmin-pad xmax+pad];
    end

    if isempty(allY)
        ylim_use = [0 1];
    else
        ymin = min(allY);
        ymax = max(allY);
        if ymin == ymax
            ymin = ymin - 1;
            ymax = ymax + 1;
        end
        pad = 0.08 * (ymax - ymin);
        ylim_use = [ymin-pad ymax+pad];
    end
end