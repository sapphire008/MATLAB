function DH = dicom_GE_slice_order(dicom_folder,verbose)
% Get slice order information from dicom images
% dicom_GE_slice_order(dicom_folder)
% Inputs:
%       dicom_folder: full path of the folder that contains .dcm files
%       verbose: [true|false]: whether or not to display extracted
%                information. Default false
% Outputs:
%       DH: a structure with the following fields
%           a). TR
%           b). number_of_slices
%           c). number_of_volumes
%           d). slice_acquisition_order: ['interleaved' | 'sequential']
%   

% parse input
if nargin<2 || isempty(verbose)
    verbose = false;
end

% get a list of dicom files
files = dir(fullfile(dicom_folder,'*.dcm'));
files = {files.name};
if isempty(files)
    error('Empty directory');
else
    files = cellfun(@(x) fullfile(dicom_folder,x),files,'un',0);
end


% only get the following tags
tags = {'TriggerTime',...
    'NumberOfAcquisitions',...
    'ImagesInAcquisition','NumberOfTemporalPositions','InstanceNumber',...
    'InStackPositionNumber','RepetitionTime','LocationsInAcquisition'};

% get relevant dicom headers
dicom_headers = dicom_header_matlab(files,tags);

% sort the dicom images by Instance Number (numbers the ordinal of
% this iamge)
dicom_headers(cell2mat({dicom_headers.InstanceNumber})) = dicom_headers;

% place holding a structure
DH = struct;

% inspecting TR
DH = check_uniform_field(dicom_headers,'RepetitionTime',DH,'TR','TR',...
    [],verbose);

% get number of volumes
DH = check_uniform_field(dicom_headers,'NumberOfTemporalPositions',DH,...
    'number_of_volumes','Number of Volumes',1,verbose);

% get number of slices
DH = check_uniform_field(dicom_headers,'LocationsInAcquisition',DH,...
    'number_of_slices','Number of Slices',[],verbose);

% get slice number and order
SliceNumber = cell2mat({dicom_headers.InStackPositionNumber});
SliceNumber = SliceNumber(1:DH.number_of_slices);

% get Trigger Time
TriggerTime = cell2mat({dicom_headers.TriggerTime});
TriggerTime = TriggerTime(1:DH.number_of_slices);

% get the order of the slice timing
ORDERMAT = [SliceNumber(:),TriggerTime(:),zeros(length(TriggerTime(:)),1)];

% sort slice in ascending order first
ORDERMAT = sortrows(ORDERMAT,1);

% get only the first volume
ORDERMAT = ORDERMAT(1:DH.number_of_slices,:);

% check if there is any missing slice
if range(diff(ORDERMAT(:,1)))>0
    S = warning('QUERY','BACKTRACE');%turn off backtrace
    warning('off','BACKTRACE');
    warning('Some slice are missing\n');
    warning(S.state,'BACKTRACE');%restore backtrace to original state 
end

% check if the slice is acquired in sequence or interleaved
[~,ORDERMAT(:,3)] = sort(ORDERMAT(:,2),1,'ascend');

% output order
D = sort(unique(diff(ORDERMAT(:,3))),1,'ascend');
if all(D==1) || all(D==-1)
    DH.slice_acquisition_order = 'Sequential';
    if verbose
        fprintf('Slice Order:%s\n',DH.slice_acquisition_order);
    end
elseif D(1) == (2-DH.number_of_slices) && D(2) ==2
    SliceAcquisitionOrder = 'Interleaved';
    if mod(ORDERMAT(1,1),2) == 1
        DH.slice_acquisition_order = [SliceAcquisitionOrder,'-Odd-First'];
    else
        DH.slice_acquisition_order = [SliceAcquisitionOrder,'-Even-First'];
    end
    if verbose
        fprintf('Slice Order:%s\n',DH.slice_acquisition_order);
    end
else
    DH.slice_acquisition_order = ...
        sprintf('Unrecognized Slice Acquisition Order:\n%s%s',...
        sprintf('%d,',ORDERMAT(1:end-1,3)),sprintf('%d',ORDERMAT(end,3)));
    S = warning('QUERY','BACKTRACE');%turn off backtrace
    warning('off','BACKTRACE');
    warning('%s\n',DH.slice_acquisition_order);
    warning(S.state,'BACKTRACE');%restore backtrace to original state
end
end

function DH = check_uniform_field(dicom_headers,DICOMFIELDNAME,DH,...
    INFOFIELDNAME,MESSAGE,DEFAULT,verbose)
try 
    K = cell2mat({dicom_headers.(DICOMFIELDNAME)});
catch %#ok<CTCH>
    S = warning('QUERY','BACKTRACE');%turn off backtrace
    warning('off','BACKTRACE');
    warning('No such field: %s\n trying to use default.\n',DICOMFIELDNAME);
    warning(S.state,'BACKTRACE');%restore backtrace to original state
    DH.(INFOFIELDNAME) = DEFAULT;
    return;
end
if range(K)>0
    DH.(INFOFIELDNAME) = [];
    S = warning('QUERY','BACKTRACE');%turn off backtrace
    warning('off','BACKTRACE');
    warning('%s are not consistent\n',MESSAGE);
    warning(S.state,'BACKTRACE');%restore backtrace to original state
else
    DH.(INFOFIELDNAME) = K(1);
    if verbose
        fprintf('%s : %d\n',MESSAGE,K(1));
    end
end
end