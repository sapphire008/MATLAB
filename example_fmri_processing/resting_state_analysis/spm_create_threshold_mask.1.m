% create mask from average partial    
for n = 1:length(P)
    V = spm_vol(P{n});
    [PATHSTR,NAME,EXT] = fileparts(V.fname);
    V.fname = fullfile(PATHSTR,[NAME,'_mask',EXT]);
    IMAGE = double(V.private.dat);
    IMAGE(isnan(IMAGE)) = 0;
    IMAGE(IMAGE<100) = 0;
    IMAGE(IMAGE>=100) = 1;
    V = spm_create_vol(V);
    V = spm_write_vol(V,IMAGE);
    clear V;
end

% for intersection masks
P = SearchFiles('/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/sources/',...
    'wx*_mask.nii');
P = P([3:17,23:24]);
IMAGE = true(157,189,156);
for n = 1:length(P)
    V = spm_vol(P{n});
    IMAGE = double(V.private.dat) & IMAGE;
end
V.fname = '/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/AverageMaps/wxaverage_mask.nii';
V = spm_create_vol(V);
V = spm_write_vol(V,IMAGE);

% mask the resulted averages
M = spm_vol('/hsgs/projects/jhyoon1/midbrain_pilots/RestingState/analysis/Connectivity/AverageMaps/wxaverage_mask.nii');
M = double(M.private.dat);
for n = 1:length(P)
    V = spm_vol(P{n});
    IMAGE = double(V.private.dat);
    IMAGE(~M) = NaN;
    [PATHSTR,NAME,EXT] = fileparts(V.fname);
    V.fname = fullfile(PATHSTR,['control_',NAME,EXT]);
    V = spm_create_vol(V);
    V = spm_write_vol(V,IMAGE);
    clear V;
end