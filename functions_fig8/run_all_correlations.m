function CorrTab = run_all_correlations(G, groupLabel, apply3sd)
    rows = cell(0,11);

    % Overall learning rate
    rows = [rows;
        corr_row(G.Anxiety, G.LearningRateMean.S1, groupLabel, 'S1', 'Overall Learning Rate', apply3sd);
        corr_row(G.Anxiety, G.LearningRateMean.S2, groupLabel, 'S2', 'Overall Learning Rate', apply3sd)];

    % Condition-wise LR
    conds = {'HP','MP','UP'};
    for c = 1:3
        rows = [rows;
            corr_row(G.Anxiety, G.LearningRate.S1(:,c), groupLabel, 'S1', ['Learning Rate - ' conds{c}], apply3sd);
            corr_row(G.Anxiety, G.LearningRate.S2(:,c), groupLabel, 'S2', ['Learning Rate - ' conds{c}], apply3sd)];

        rows = [rows;
            corr_row(G.Anxiety, G.Accuracy.S1(:,c), groupLabel, 'S1', ['Accuracy - ' conds{c}], apply3sd);
            corr_row(G.Anxiety, G.Accuracy.S2(:,c), groupLabel, 'S2', ['Accuracy - ' conds{c}], apply3sd)];
    end

    % VKF summary parameters
    rows = [rows;
        corr_row(G.Anxiety, G.Lambda.S1, groupLabel, 'S1', 'Volatility Update Rate', apply3sd);
        corr_row(G.Anxiety, G.Lambda.S2, groupLabel, 'S2', 'Volatility Update Rate', apply3sd);
        corr_row(G.Anxiety, G.V0.S1,     groupLabel, 'S1', 'Initial Volatility v0', apply3sd);
        corr_row(G.Anxiety, G.V0.S2,     groupLabel, 'S2', 'Initial Volatility v0', apply3sd);
        corr_row(G.Anxiety, G.Omega.S1,  groupLabel, 'S1', 'Meta-volatility omega', apply3sd);
        corr_row(G.Anxiety, G.Omega.S2,  groupLabel, 'S2', 'Meta-volatility omega', apply3sd)];

    CorrTab = cell2table(rows, 'VariableNames', ...
        {'Group','Control','Outcome','N','r','p','CI_low','CI_high','R2','X_mean','Y_mean'});
end