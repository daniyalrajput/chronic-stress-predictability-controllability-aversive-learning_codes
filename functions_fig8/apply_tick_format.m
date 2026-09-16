
function apply_tick_format(ax, axis_name, fmt, nTicks)
    if nargin < 4
        nTicks = 5;
    end
    switch lower(axis_name)
        case 'y'
            yl = ax.YLim;
            yt = linspace(yl(1), yl(2), nTicks);
            ax.YTick = yt;
            ax.YTickLabel = cellstr(compose(fmt, yt));
        case 'x'
            xl = ax.XLim;
            xt = linspace(xl(1), xl(2), nTicks);
            ax.XTick = xt;
            ax.XTickLabel = cellstr(compose(fmt, xt));
    end
end