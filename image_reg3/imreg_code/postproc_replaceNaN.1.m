function worksheet=postproc_replaceNaN(worksheet,replace_cell)
nan_entry=cellfun(@(x) isnan(x),worksheet,'UniformOutput',false);
nan_index=cellfun(@sum,nan_entry);
worksheet(nan_index==1)=replace_cell;
end