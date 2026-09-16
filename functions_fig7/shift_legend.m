function shift_legend(lgd, dx, dy)
    pos = lgd.Position;
    pos(1) = pos(1) + dx;
    pos(2) = pos(2) + dy;
    lgd.Position = pos;
end