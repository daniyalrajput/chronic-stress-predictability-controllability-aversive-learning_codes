function summary_tbl = set_summary(summary_tbl, effectName, F, df1, df2, p)
    idx = summary_tbl.Effect == effectName;
    summary_tbl.FStat(idx) = F;
    summary_tbl.DF1(idx) = df1;
    summary_tbl.DF2(idx) = df2;
    summary_tbl.pValue(idx) = p;
end