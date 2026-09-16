function apply_y_tick_format(ytick_vals)
    if all(abs(ytick_vals - round(ytick_vals)) < 1e-10)
        ytickformat('%.0f');
    elseif all(abs(ytick_vals*10 - round(ytick_vals*10)) < 1e-10)
        ytickformat('%.1f');
    else
        ytickformat('%.2f');
    end
end