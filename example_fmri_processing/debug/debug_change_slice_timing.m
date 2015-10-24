%debug batch change slice timing
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913'};
ext = '.mat';
for s = 1:length(subjects)
    clear matlabbatch;
    load([subjects{s},ext]);
    for f = 1:length(matlabbatch)
        try
            matlabbatch{f}.spm.temporal.st.so = matlabbatch{f}.spm.temporal.st.nslices:-1:1;
            matlabbatch{f}.spm.temporal.st.refslice = matlabbatch{f}.spm.temporal.st.nslices;
        catch
            continue;
        end
    end
    eval(['!cp ',[subjects{s},'.mat '],[subjects{s},'_backup.mat']]);
    save([subjects{s},'.mat'],'matlabbatch');
end