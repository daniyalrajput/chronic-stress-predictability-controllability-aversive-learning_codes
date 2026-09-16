function ids = canonicalize_id_vector(x)

    if isstring(x)
        x = cellstr(x);
    elseif isnumeric(x)
        x = num2cell(x);
    elseif ~iscell(x)
        x = num2cell(x);
    end

    ids = cell(size(x));

    for i = 1:numel(x)
        v = x{i};

        if isempty(v)
            ids{i} = '';
            continue;
        end

        if isnumeric(v)
            s = num2str(v);
        elseif isstring(v)
            s = char(v);
        elseif ischar(v)
            s = v;
        else
            try
                s = char(string(v));
            catch
                ids{i} = '';
                continue;
            end
        end

        s = upper(strtrim(s));
        s = regexprep(s, '_CLEANED$', '', 'ignorecase');
        s = regexprep(s, '_(S1|S2)$', '', 'ignorecase');
        s = regexprep(s, '\.0$', '');

        tok = regexp(s, '([A-Z]*)(\d+)', 'tokens', 'once');

        if isempty(tok)
            ids{i} = s;
        else
            prefix = tok{1};
            numstr = tok{2};
            if isempty(prefix)
                ids{i} = sprintf('%03d', str2double(numstr));
            else
                ids{i} = [prefix sprintf('%03d', str2double(numstr))];
            end
        end
    end
end