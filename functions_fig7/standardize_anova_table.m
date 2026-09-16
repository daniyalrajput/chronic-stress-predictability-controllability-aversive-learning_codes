function T = standardize_anova_table(T)
    if ~istable(T), return; end
    vn = T.Properties.VariableNames;

    if any(strcmpi(vn,'Term'))
        T.Term = string(T.Term);
    elseif any(strcmpi(vn,'Name'))
        T.Term = string(T.Name);
    else
        T.Term = string((1:height(T)).');
    end

    T = movevars(T,'Term','Before',1);
end