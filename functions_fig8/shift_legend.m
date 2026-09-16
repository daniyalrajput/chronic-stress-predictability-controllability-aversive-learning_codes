function shift_legend(lgd, dx, dy)
    try
        old_units = lgd.Units;
        lgd.Units = 'normalized';
        pos = lgd.Position;
        pos(1) = pos(1) + dx;
        pos(2) = pos(2) + dy;
        lgd.Position = pos;
        lgd.Units = old_units;
    catch
    end
end