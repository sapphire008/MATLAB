function GS = RSA_ROI_timeseries(P,Mask,varargin)
% GS = RSA_global_signal(P, Mask, 'option','val')
% compute a seed based correlation map
% Inputs:
%       P: strings or cellstr of file paths.
%       save_name: name to save the file as
%       Mask: Optional; mask image, to focus only on the mask voxels.
%             Similar to the ROI argument, this can be path, loaded image,
%             or 3D image itself
%       opt: further process the extracted time series
%               1).'detrend': remove linear trend from the time series
%               2).'zeromean': remove mean from the time series
%               3).'butter': Butterworth filter. Specify {Ns,'high/low'}
%                  in 'val' to indicate: a). Ns = how many scans in the
%                  time window, and b). 'high' or 'low' pass filter
%            The order of signal processing will be the same as the order
%            specified.
% Outputs:
%       GS: Time series of global signal


% read in the figure handles
V = spm_vol(char(P));%this is not actually loading in the images

% get the mask XYZ index
Mask_XYZ = get_roi_index(Mask);

% get time series from the Mask_XYZ
GS = mean(spm_get_data(V,Mask_XYZ),2);

% free some memory before processing to the next
clear V P Mask_XYZ;

% post process extracted time series
% parse optional inputs
opt_list = {'detrend','zeromean','butter'};
[flag,ord] = ParseOptionalInputs(varargin,opt_list,{false,false,[]});
%perform each post processing in the order
for n = ord
    switch opt_list{n}
        case 'detrend'
            GS = detrend(GS);
        case 'zeromean'
            GS = detrend(GS,'constant');
        case 'butter'
            mean_GS =  mean(GS,1);%calculate column mean
            GS = bsxfun(@minus, GS, mean_GS);%remove mean from each column
            [B,A] = butter(3,1/flag.butter{1},flag.butter{2});
            GS = filtfilt(B,A,GS);%filter
            GS = bsxfun(@plus, GS, mean_GS);%add mean back
    end
end
end

%% Sub-functions

%%%%%%%%%%%%%%%%%%%%%%%%%% Get ROI/Mask index %%%%%%%%%%%%%%%%%%%%%%%%%
function [index,ROI_Size]= get_roi_index(ROI)
if isempty(ROI)
    index = NaN;
    return;
end
% load and get ROI XYZ coordinates
switch class(ROI)
    case 'char'%assume path to seed image
        ROI = load_nii(ROI);
        ROI = ROI.img;
    case 'struct'%assume image loaded by load_nii
        ROI = ROI.img;
%otherwise, assume ROI is already a 3D image
end
% get the image of the ROI, must be loaded first as a 3D image
ROI_Size = size(ROI);
[X,Y,Z] = ind2sub(ROI_Size,find(ROI));
index = [X(:)';Y(:)';Z(:)'];
end

%%%%%%%%%%%%%%%%%%%%%%%%% parse optional inputs %%%%%%%%%%%%%%%%%%%%%%%%%
function [flag,ord]=ParseOptionalInputs(varargin_cell,keyword,default_value)
% Inspect whether there is a keyword input in varargin, else return 
% default. If search for multiple keywords, input both keyword and 
% default_value as a cell array of the same length.
% If length(keyword)>1, return flag as a structure
% else, return the value of flag without forming a structure
%
% [flag,ord] = ParseOptionalInputs(varargin_cell,keyword, default_value)
% 
% Inputs: 
%   varargin_cell: varargin cell
%   keyword: flag names
%   default_value: default value if there is no input
%
% Outputs:
%   flag: structure with field names identical to that of keyword
%   ord: order of keywords being input in the varargin_cell. ord(1)
%        correspond to the index of the keyword that first appeared in the
%        varargin_cell
%
%
% Edward Cui. Last modified 12/13/2013
% 

%flag unbalanced input 
if length(keyword)~=length(default_value) 
    error('keyword and default_value must be the same length');
end

%convert everything into cell array if single input
if ~iscell(keyword)
    keyword={keyword};
end
if ~iscell(default_value)
    default_value={default_value};
end

%place holding
flag=struct();
ord = [];

% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:2:length(varargin_cell)
    IND = find(strcmpi(varargin_cell(n),keyword),1);
    if ~isempty(IND)
        flag.(keyword{IND}) = varargin_cell{n+1};
        ord = [ord, IND];
    else
        flag.(keyword{IND}) = default_value{IND};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end

end