function h = make_box_legend_proxies(colH_S1,colH_S2,colC_S1,colC_S2,box_alpha)
    hold on;
    h(1) = patch(nan,nan,colH_S1,'FaceAlpha',box_alpha,'EdgeColor',colH_S1,'LineWidth',1.4);
    h(2) = patch(nan,nan,colH_S2,'FaceAlpha',box_alpha,'EdgeColor',colH_S2,'LineWidth',1.4);
    h(3) = patch(nan,nan,colC_S1,'FaceAlpha',box_alpha,'EdgeColor',colC_S1,'LineWidth',1.4);
    h(4) = patch(nan,nan,colC_S2,'FaceAlpha',box_alpha,'EdgeColor',colC_S2,'LineWidth',1.4);
end