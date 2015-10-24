function block_index = index_images_for_range_of_blocks(SPM,block_numbers)
% block_index = index_images_per_block(SPM)
% block_index - a per block index of the image volumnes - to be used with
% SP.xY.P
% SPM - the SPM data structure

first = 1;

for n = 1:length(SPM.nscan)
    fullblock_index{n} = first:SPM.nscan(n)+first-1;
    first = first + SPM.nscan(n);
    
end

j=1

for n = block_numbers
    block_index{j} = fullblock_index{n};
    j = j + 1;
end