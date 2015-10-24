%purge my files
base_dir = '/nfs/jong_exp/midbrain_pilots/mid/analysis/GLM/';
target_files = {'*.hdr','*.img','SPM.mat'};
flag.verbose = 1;


%display warning message
warning('Use with Caution!');
%list all folders and files in the base directory
[P,F] = subdir(base_dir);

%remove files
target_IND = {};
for n = 1:length(F)
    if isempty(F{n})
        continue;
    end
    for m = 1:length(target_files)   
        eval(['!rm -r ', fullfile(P{n},target_files{m})]);
    end
end

