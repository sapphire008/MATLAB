%inspect_ROIs

ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR2/';
Func_dir = '/nfs/jong_exp/midbrain_pilots/stop_signal/subjects/funcs/';
ROI_suffix = '_TR2_ACPC_SNleft_STNleft.nii';
subjects = {'MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP120_060513','MP121_060713','MP122_061213',...
    'MP123_061713','MP124_062113'};
blocks = {'block1','block2','block3'};
template_file = '2sresample*.nii';
%addpath('/nfs/pkg64/contrib/nifti/');
% Place holding for a cell array of ROI_quality
ROI_quality = struct([]);
% display only a portion of the image and ROI
%{[saggital],[coronal],[axial]};
%crop_3D = {85:120,65:130,67:130};
IND = 1;
for s = 1:length(subjects)
    clear ROI b Template_dir;
    %find ROI
    ROI = fullfile(ROI_dir,[subjects{s},ROI_suffix]);
    
    %find a list of templates to be inspected
    for b = 1:length(blocks)
        clear tmp;
        tmp = dir(fullfile(Func_dir,subjects{s},blocks{b},template_file));
        image_dirs = cellfun(@(x) fullfile(Func_dir,subjects{s},blocks{b},x),...
            {tmp.name},'un',0);
        
        %inspect each template
        ROI_quality(IND).subject = subjects{s};
        ROI_quality(IND).block = blocks{b};
        ROI_quality(IND).ROI_dir = ROI;
        ROI_quality(IND).quality = ROI_display(image_dirs, ROI,...
            [subjects{s},' | stop_signal | ',ROI_suffix],'coronal',0.10);
       
        IND = IND+1;%go to next round
    end
    
end