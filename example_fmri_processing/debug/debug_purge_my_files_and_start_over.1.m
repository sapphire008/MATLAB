%purge my files and start over
base_dir = '/nfs/jong_exp/midbrain_pilots/';
studies ={'RestingState','4POP','frac_back','mid','stop_signal'};
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913'};
block_num = [0,8,3,2,3];
for n = 1:length(studies)
    blocks = cellfun(@(x) ['block',num2str(x)], num2cell(1:block_num(n)),'un',0);
    if isempty(blocks)
        blocks{1} = '';
    end
    for s = 1:length(subjects)
        %purge analysis
        tmp_list = dir(fullfile(base_dir,studies{n},'analysis'));
        all_directories=arrayfun(@(x) x.name,tmp_list(3:end),'un',0);
        for gg = 1:length(all_directories)
            evalc(['!rm -r ',fullfile(base_dir,studies{n},'analysis',all_directories{gg},subjects{s},'*.hdr')]);
            evalc(['!rm -r ',fullfile(base_dir,studies{n},'analysis',all_directories{gg},subjects{s},'*.img')]);
            evalc(['!rm -r ',fullfile(base_dir,studies{n},'analysis',all_directories{gg},subjects{s},'SPM.mat')]);
        end
%         %purge funcs
%         for b = 1:length(blocks)
%             %remove processed nifti files starting with time slicing
%             T1=evalc(['!rm -r ', fullfile(base_dir,studies{n},'subjects','funcs',subjects{s},blocks{b},'*a*.nii')]);
%             %remove movement parameter text files
%             T2=evalc(['!rm -r ', fullfile(base_dir,studies{n},'subjects','funcs',subjects{s},blocks{b},'*rp*.txt')]);
%         end
    end
end
