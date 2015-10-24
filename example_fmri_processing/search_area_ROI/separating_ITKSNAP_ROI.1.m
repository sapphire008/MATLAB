function ROI_cluster_out = separating_ITKSNAP_ROI(...
    original_ROI_dir,cluster_names,cluster_colors,save_dir,verbose)
% [ROI_cluster_out] = separating_ITKSNAP_ROI(original_ROI_dir, cluster_names, cluster_colors, save_dir,verbose)
% separating ITK-SNAP drawn ROIs. One ROI with one label.
% Requires NIFTI pacakge by Jimmy Shen
%
% Required Inputs:
%       original_ROI_dir: directory of the source ROI to be separated
%       
%       cluster_names: cellstr of cluster names
%
%       cluster_colors: color codings of each ROI cluster corresponding to
%                       cluster_names. Specify either Name or Color number.
%       
%       Note: cluster_names must corresponds to cluster_colors in order.
%       
%       List of color codings:
%                        Name           Color number
%                       'ClearLabel':        0;
%                       'Red':               1;
%                       'Green':             2;
%                       'Blue':              3;
%                       'Yellow':            4;
%                       'Cyan':              5;
%                       'Magenta':           6;
%                       'Violet':            7;
%                       'Orange':            8;
%                       'Pink':              9;
%                       'Azul':             10;
%                       'Turquoise':        11;
%                       'White':            12;
%                       'Brown':            13;
%
%       save_dir: directory to save the ROI. 
%                 If desired to include a prefix to the saved file name, 
%                 specify the path in addition to the fileprefix and file
%                 extension (.nii) like the following:
%                               save_dir/prefix.nii
%                 The name of the ROI will be appended automatically, 
%                 making the saved ROI file name like the following:
%                           save_dir/prefix_ROI_name.nii
%
% Optional Input:
%       verbose: 0 | 1, display information about ROI, default off (0)
%       
% Optional Output:
%       If desired, instead of specifying save_directory, supply an output
%       variable to retain the separted ROI in the memory, instead of
%       writing them onto the hard drive. Each ROI will be stored as only
%       the 1D index of the image, with size of the image also stored.
%       matrix in an array of structures.

% original_ROI_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP022_051713_TR3_ACPC_SNleft_STNleft.nii';
% cluster_names = {'SNleft','STNleft','ACPC'};
% cluster_colors = {1,4,2};
% save_dir = '/nfs/jong_exp/midbrain_pilots/ROIs/TR3/MP022_051713.nii';

%ITK-snap color coding
ColorDictionary = {...
    'ClearLabel', 0;
    'Red',1;
    'Green',2;
    'Blue',3;
    'Yellow',4;
    'Cyan',5;
    'Magenta',6;
    'Violet',7;
    'Orange',8;
    'Pink',9;
    'Azul',10;
    'Turquoise',11;
    'White',12;
    'Brown',13};
ColorDictionary2 = cell2struct(ColorDictionary(:,2),ColorDictionary(:,1));

%sanity check
%make sure cluster_names and cluster_colors have the same length
if length(cluster_names) ~= length(cluster_colors)
    error('Cluster names and cluster colors must have the same length');
end
%check whether the argument save_dir or output variable exist
if nargin<4 && nargout == 0
    error('Specify either an output variable or specify a save directory');
end
% check verbose argument
if nargin<5
    verbose = false;
end
%make sure cluster_colors are in cell array
if isnumeric(cluster_colors)
    cluster_colors = num2cell(cluster_colors);
elseif iscellstr(cluster_colors)%if input as color names
    cluster_colors = cellfun(@(x) ColorDictionary2.(x),cluster_colors,'un',0);
end

% load ROI
ROI = load_nii(original_ROI_dir);

%find all the clusters within this ROI
clear cluster_index_all cluster_color_all;
cluster_index_all = find(ROI.img);
cluster_color_all = ROI.img(cluster_index_all);

% return ROIs
if nargin>3 && ~isempty(save_dir)%choose to save the ROI to the hard drive
    %inspect save_dir
    try
        [PATHSTR,NAME,EXT] = fileparts(save_dir);
    catch ERR
        error('Invalid save_dir');
    end
    if ~isempty(NAME)
        save_dir = PATHSTR;
        NAME = [NAME,'_'];
    end
    if isempty(EXT)
        EXT = '.nii';
    end
    
    %separating the clusters and save into a file
    for n = 1:length(cluster_names)
        clear tmp;
        tmp = ROI;%pass down general ROI info
        tmp.img = zeros(size(tmp.img));%remove all clusters
        %store only corresponding clusters
        tmp.img(cluster_index_all(cluster_color_all == ...
            cluster_colors{n})) = cluster_colors{n};
        %save clusters
        save_nii(tmp,fullfile(save_dir,[NAME,cluster_names{n},EXT]));
    end
end
if nargout>0%return my ROI clusters
    ROI_cluster_out = repmat(struct,1,length(cluster_names));
    for n = 1:length(cluster_names)
        ROI_cluster_out(n).color_value = cluster_colors{n};
        ROI_cluster_out(n).color_name = ColorDictionary{find(...
            cell2mat(ColorDictionary(:,2)) == cluster_colors{n}),1};
        ROI_cluster_out(n).cluster_name = cluster_names{n};
        ROI_cluster_out(n).ind = cluster_index_all(cluster_color_all == cluster_colors{n});
        ROI_cluster_out(n).template_size = size(ROI.img);
        
        %display ROI info if turning on verbose
        if verbose
            disp(['name: ', ROI_cluster_out(n).cluster_name]);
            disp(['size: ', num2str(length(ROI_cluter_out(n).ind))]);
            disp(['color: ',ROI_cluster_out(n).color_name]);
        end
    end
end
if (isempty(save_dir) || nargin<4) && nargout<1
    error('Please specify either a save_dir or request an output');
end
end
