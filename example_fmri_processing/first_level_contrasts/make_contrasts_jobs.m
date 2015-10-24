function  matlabbatch = make_contrasts_jobs(str,contrasts)
% jobs = make_contrasts_jobs(str,contrasts);
% contrast is the argument returned by make_contrasts_SPM script
% contrast is a structure - contrasts.name and contrasts.con
% name is a cell array of contrast name strings
% vectors is a cell array of contrast vectors
% str is optional, if missing a selection window will pop up
% str should pointer to the SPM.mat file for the subject
switch nargin,
    case 0,
        disp('You need to provide at least one argument');
        jobs = {};
        return;

    case 1,
        [t,sts] = spm_select(1,'^SPM\.mat$','Select SPM.mat');
        matlabbatch{1}.spm.stats(1).con.spmmat = cellstr(t);

        matlabbatch{1}.spm.stats(1).con.delete = 1;

        for k = 1:length(contrasts)
            matlabbatch{1}.spm.stats(1).con.consess{k}.fcon.name = contrasts(k).name;
            matlabbatch{1}.spm.stats(1).con.consess{k}.fcon.sessrep = 'none';
            matlabbatch{1}.spm.stats(1).con.consess{k}.fcon.convec = contrasts(k).con;
        end
    case 2,
        [t,sts] = spm_select('Filter',str,'mat');
        %[t,sts] = spm_select(1,'^SPM\.mat$','Select SPM.mat');
        matlabbatch{1}.spm.stats(1).con.spmmat = cellstr(t);

        matlabbatch{1}.spm.stats(1).con.delete = 1;

        for k = 1:length(contrasts)
            matlabbatch{1}.spm.stats(1).con.consess{k}.tcon.name = contrasts(k).name;
            matlabbatch{1}.spm.stats(1).con.consess{k}.tcon.sessrep = 'none';
            matlabbatch{1}.spm.stats(1).con.consess{k}.tcon.convec = contrasts(k).con;
        end
end
