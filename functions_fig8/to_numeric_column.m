function v = to_numeric_column(col)
    if isnumeric(col)
        v = double(col); return;
    end
    if islogical(col)
        v = double(col); return;
    end
    if isstring(col)
        col = cellstr(col);
    end
    if iscell(col)
        v = nan(size(col,1),1);
        for i = 1:size(col,1)
            x = col{i};
            if isnumeric(x) && isscalar(x)
                v(i) = double(x);
            elseif islogical(x) && isscalar(x)
                v(i) = double(x);
            elseif ischar(x) || isstring(x)
                s = strtrim(string(x));
                val = str2double(s);
                if ~isnan(val)
                    v(i) = val;
                else
                    if any(strcmpi(s, ["Correct","1"]))
                        v(i) = 1;
                    elseif any(strcmpi(s, ["Incorrect","0"]))
                        v(i) = 0;
                    else
                        v(i) = NaN;
                    end
                end
            else
                v(i) = NaN;
            end
        end
        v = v(:);
        return;
    end
    v = nan(numel(col),1);
end