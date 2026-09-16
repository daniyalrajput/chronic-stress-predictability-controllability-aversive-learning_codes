function h = make_corr_legend_proxies(col1,col2)
    hold on;
    h(1) = scatter(nan,nan,55,'o','MarkerFaceColor',col1,'MarkerEdgeColor','k','MarkerFaceAlpha',0.85,'MarkerEdgeAlpha',0.85);
    h(2) = scatter(nan,nan,55,'s','MarkerFaceColor',col2,'MarkerEdgeColor','k','MarkerFaceAlpha',0.85,'MarkerEdgeAlpha',0.85);
end