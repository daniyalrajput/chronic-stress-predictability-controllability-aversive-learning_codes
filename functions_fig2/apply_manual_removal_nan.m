function [x, nRemoved] = apply_manual_removal_nan(x, idxRemove, valRemove, label)
    nRemoved = 0;

    if ~isempty(idxRemove)
        idxRemove = idxRemove(idxRemove >= 1 & idxRemove <= numel(x));
        x(idxRemove) = NaN;
        nRemoved = nRemoved + numel(idxRemove);
    end

    if ~isempty(valRemove)
        for i = 1:numel(valRemove)
            target = valRemove(i);
            idx = find(abs(x - target) < 1e-4, 1, 'first');
            if ~isempty(idx)
                x(idx) = NaN;
                nRemoved = nRemoved + 1;
            else
                warning('Value %.4f not found for %s.', target, label);
            end
        end
    end
end
