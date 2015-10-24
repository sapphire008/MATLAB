base_dir = '/hsgs/projects/jhyoon1/midbrain_Stanford_3T/test_drive/funcs/M3038_CNI_030614/';
folders = {'1_MUX2_TE34','4_MUX2_TE36','5_MUX2_2_TE34'};
% addspm8
% addmatlabpkg('fMRI_pipeline');
TR = 2;
mux = 2;

for n = 1:length(folders)
    P = SearchFiles(fullfile(base_dir,folders{n}),'0*.nii');
    V = spm_vol(P{1});
    numslices = V.dim(3);
    clear V;
    sliceorder = [1:2:(numslices/mux),2:2:(numslices/mux)];
    for k = 1:(mux-1)
        sliceorder = [sliceorder;sliceorder+numslices/mux*k];
    end
    refslice = sliceorder(:,1)';
    timing(1) = TR/numslices*mux;
    timing(2) = timing(1);
    prefix = 'a';
    spm_slice_timing_mux(char(P), sliceorder, refslice, timing, prefix);
end