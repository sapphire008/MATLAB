function [beta_idx beta_names] = group_beta_images_by_block_condition_basis( SPM )
%updated for uneven blocks


discrip = {SPM.Vbeta.descrip};

% locate and remove constants
const = strfind(discrip,'constant');
const = find(~cellfun('isempty',const));
discrip = {discrip{1:const(1)-1}};
beta_idx = [];


for n = 1:length(const) % assumeing one block for each constant
    % locate the index for each Block of betas
    block = ['Sn(',num2str(n),')'];
    Block_idx = find(~cellfun('isempty',strfind(discrip,block)));% find all betas in block
    Block_idx = Block_idx(:);%am
    % locate the position of the first basis function for each conditions
    first_basis = find(~cellfun('isempty',strfind({discrip{Block_idx}}, 'bf(1)')));
%     % assume distance between conditions is equal to numbre of basis
     %num_of_basis = first_basis(2) - first_basis(1);
    %count the number of basis functions used in convolution 
     num_of_basis = cellfun(@(x) x(regexp(x,'bf\((\d*)\)')+3),discrip(Block_idx),'un',0);
     num_of_basis = max(cell2mat(cellfun(@str2num,num_of_basis,'un',0)));
    for k = first_basis
        %convert index local to the current block to the index used by SPM.Vbeta
        beta_idx = [beta_idx;Block_idx(k)];
        % generate file names
        %index of 'Sn' and 'bf' characters in the description
        idx = [strfind(SPM.Vbeta(Block_idx(k)).descrip,'Sn('),...
            strfind(SPM.Vbeta(Block_idx(k)).descrip,'bf(1)')];
        %format file names correctly
        filename = SPM.Vbeta(Block_idx(k)).descrip(idx(1):idx(2)-2);
        filename = regexprep(filename, {'\s','(',')','__'},{'_','_','_','_'});
        %store file name
        beta_names{size(beta_idx,1)} = filename;
    end
    block = regexprep(block,num2str(n),num2str(n+1));
end


