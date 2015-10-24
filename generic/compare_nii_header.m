function [TF,MSG] = compare_nii_header(img1,img2)
%img1 = '/hsgs/projects/jhyoon1/midbrain_pilots/mid/subjects/funcs/MP124_062113/block2/2sresample_rra0001.nii';
%img2 = '/hsgs/projects/jhyoon1/midbrain_pilots/VTA_ROI_localization/ROIs/TR2/MP124_062113_TR2_SNleft.nii';
global count_msg msg;
count_msg = 0;
msg = {};
addmatlabpkg('NIFTI');
img1 = load_untouch_header_only(img1);
img2 = load_untouch_header_only(img2);
compare_struct_fields(img1,img2);
TF = isempty(msg);
MSG = msg;
end

function TF = compare_struct_fields(varargin)
global count_msg; global msg;
S = varargin; clear varargin;
S = cellfun(@orderfields,S,'un',0);
% get the field names
F = cellfun(@fieldnames,S,'un',0);
% see if they all have identical fields
TF = range(cellfun(@length,F))==0;
if ~TF
    count_msg = count_msg +1;
    msg{count_msg} = 'field numbers are not identical';
    return;
end
% if they have identical numbers of fields, try to see if all the field
% names are identical
TF = comp_cellstr(F);
if ~ TF
    count_msg = count_msg +1;
    msg{count_msg} = 'fields are not identical';
    return;
end
% if they have identical fields, try to see if the values of the fields are
% identical or not
for n = 1:length(F{1})
    K = cellfun(@getfield,S,cellfun(@(x) x{n},F,'un',0),'un',0);
    if isstruct(K{1})
        TF = compare_struct_fields(K{:});
    elseif ischar(K{1})
        TF = comp_cellstr(K);
    elseif isnumeric(K{1})
        K = cellfun(@(x) x(:)',K,'un',0);
        TF = ~any(diff(cell2mat(K(:)),1));
    else%check if class is identical
        TF = comp_cellstr(cellfun(@class,K,'un',0));
    end
    %check value of TF. Return immediately upon false
    if ~TF
        count_msg = count_msg +1;
        msg{count_msg} = sprintf('field ''%s'' are not identical',F{1}{n});
        disp(msg{count_msg});
    end
    clear K;
end
end

% check if all the elements of a cellstr are identical
function TF = comp_cellstr(CSTR)
TF = true;
for m = 2:length(CSTR)
    TF = TF & all(ismember(CSTR{1},CSTR{m}));
end
end