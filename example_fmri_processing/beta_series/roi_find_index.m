function index = roi_find_index(ROI_loc)


% read in ROI
[Y XYZ] = spm_read_vols(spm_vol(char(ROI_loc)));

[x y z] = size(Y);

% step through each slice - find x y location for ones in slice
% append x y z data to index list
index = [];
for n = 1:z
    [xx yy] = find(squeeze(Y(:,:,n)));
    if ~isempty(xx),
        zz = ones(size(xx))*n;
        index = [index,[xx';yy';zz']];
    end
end

