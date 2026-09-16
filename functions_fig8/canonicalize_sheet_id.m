function out = canonicalize_sheet_id(sheetNames)
    s = upper(strtrim(string(sheetNames)));
    s = regexprep(s, '\s+', '');
    s = regexprep(s, '_S1$|_S2$', '');
    s = regexprep(s, 'S1$|S2$', '');
    s = regexprep(s, '[^A-Z0-9]', '');
    out = s;
end