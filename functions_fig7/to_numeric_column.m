function x = to_numeric_column(v)
    if isnumeric(v)
        x = double(v);
        return;
    end

    if iscell(v)
        x = nan(size(v));
        for i = 1:numel(v)
            if isnumeric(v{i}) && isscalar(v{i})
                x(i) = double(v{i});
            elseif isstring(v{i}) || ischar(v{i})
                tmp = str2double(string(v{i}));
                if ~isnan(tmp)
                    x(i) = tmp;
                end
            end
        end
        x = x(:);
        return;
    end

    if isstring(v) || ischar(v)
        x = str2double(string(v));
        x = x(:);
        return;
    end

    x = nan(size(v));
    x = x(:);
end