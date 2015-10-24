clc;
base_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/maps/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/';
mask_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/frac_back/analysis/RissmanConnectivity/sources/Fracback_control_group_mask.nii';
% subjects = {'MP120_060513','MP121_060713','MP123_061713',...
%     'MP124_062113','MP125_072413'};
subjects = {'MP022_051713',...
    'MP023_052013','MP024_052913','MP026_062613','MP027_062713',...
    'MP028_062813','MP029_070213','MP030_070313','MP032_071013',...
    'MP033_071213','MP034_072213','MP035_072613','MP036_072913',...
    'MP037_080613'};
map_type = {'R2Z','Z_test'};
ROIs = {'SNleft','STNleft'};
task_type = {'InstructionBlock','NULL','ZeroBack','OneBack','TwoBack'};
label = 'control_connectivity_map';


XYZ = spm_vol(mask_dir);
XYZ = double(XYZ.private.dat);
for m = 1:length(map_type)
    for r = 1:length(ROIs)
        for t = 1:length(task_type)
            P = SearchFiles(base_dir,['w*',map_type{m},'*',ROIs{r},'*',task_type{t},'*.nii']);
            Q = [];
            % take the average
            for p = 1:length(P)
                if any(~cellfun(@isempty,regexp(P{p},subjects)))
                    Q = [Q,P(p)];
                end
            end
            Vi = spm_vol(char(Q));
            Vo = Vi(1);
            Vo.fname = fullfile(save_dir,...
                sprintf('%s_%s_%s_%s.nii',...
                map_type{m},ROIs{r},task_type{t},label(1:end-3)));
            f = sprintf('i%d+',1:numel(Vi));
            f = ['(',f(1:end-1),')/',num2str(numel(Vi))];
            flags.dmtx=0;
            flags.mask = 0;
            flags.interp = 4;
            Vo = spm_imcalc(Vi,Vo,f);
            Vo2 = Vo;
            Vo2.fname = fullfile(save_dir,...
                sprintf('%s_%s_%s_%s.nii',...
                map_type{m},ROIs{r},task_type{t},label));
            Vo2 = spm_create_vol(Vo2);
            K = double(Vo.private.dat);
            K(~logical(XYZ)) = 0;
            Vo2 = spm_write_vol(Vo2,K);
            delete(Vo.fname);
        end
    end
end


