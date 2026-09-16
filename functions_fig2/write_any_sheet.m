function write_any_sheet(filename, sheetname, data)
    if istable(data)
        writetable(data, filename, 'Sheet', sheetname);
    elseif isnumeric(data)
        writematrix(data, filename, 'Sheet', sheetname);
    else
        writecell(cellstr(string(data)), filename, 'Sheet', sheetname);
    end
end