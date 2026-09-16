
function apply_tick_format(ax, whichAxis, fmt, nTicks)
    switch lower(whichAxis)
        case 'x'
            lim = xlim(ax);
            ticks = linspace(lim(1), lim(2), nTicks);
            ax.XTick = ticks;
            ax.XTickLabel = arrayfun(@(v) sprintf(fmt,v), ticks, 'UniformOutput', false);
        case 'y'
            lim = ylim(ax);
            ticks = linspace(lim(1), lim(2), nTicks);
            ax.YTick = ticks;
            ax.YTickLabel = arrayfun(@(v) sprintf(fmt,v), ticks, 'UniformOutput', false);
    end
end