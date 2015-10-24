function block_index = index_images_per_block(SPM)
% block_index = index_images_per_block(SPM)
% block_index - a per block index of the image volumnes - to be used with
% SP.xY.P
% SPM - the SPM data structure


first = 1;

for n = 1:length(SPM.nscan)
    block_index{n} = first:SPM.nscan(n)+first-1;
    first = first + SPM.nscan(n);
    
end
