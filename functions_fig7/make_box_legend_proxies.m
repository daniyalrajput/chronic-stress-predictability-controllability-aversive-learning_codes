function h = make_box_legend_proxies(c1,c2,c3,c4,boxAlpha)
    h(1) = patch(nan,nan,c1,'FaceAlpha',boxAlpha,'EdgeColor','k');
    h(2) = patch(nan,nan,c2,'FaceAlpha',boxAlpha,'EdgeColor','k');
    h(3) = patch(nan,nan,c3,'FaceAlpha',boxAlpha,'EdgeColor','k');
    h(4) = patch(nan,nan,c4,'FaceAlpha',boxAlpha,'EdgeColor','k');
end