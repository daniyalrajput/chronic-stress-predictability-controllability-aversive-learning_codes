function h = make_corr_legend_proxies(c1,c2)
    h(1) = scatter(nan,nan,55,'o','MarkerFaceColor',c1,'MarkerEdgeColor','k','MarkerFaceAlpha',0.85,'MarkerEdgeAlpha',0.85);
    h(2) = scatter(nan,nan,55,'s','MarkerFaceColor',c2,'MarkerEdgeColor','k','MarkerFaceAlpha',0.85,'MarkerEdgeAlpha',0.85);
end
