function [dicom_folder,dicom_header]=dicom_mosaic(dicom_folder,vol_ind,verbose)
% dicom_mosaic(dicom_folder,vol_ind,verbose)
% given each dicom image is 2D, display dicom mosaic
% Need dicom_header_matlab and ExifTool
% 
% Inputs:
%       dicom_folder: directory that contains all the dicom images. Must be
%                     a single string. If not specified, the function will
%                     try to load the current directory
%       vol_ind: (optional) specify which volumes to load and display. If
%                not specified, will load and display all volumes in the
%                folder. vol_in does not have to be sorted; vector like
%                [3,5,1,2,4,6] is allowed, in which case the volume will be
%                displayed in the order specified in this vector.
%       verbose: (optional) [true|false] dipslay which volume and slice 
%                are loaded, including the file name of the slice.
%                Default false.
% 
% Output:
%       dicom_folder: final destination of dicom_folder. This is in case if
%                     dicom_folder is an archive
%       dicom_header: MATLAB read dicom headers

% Assuming dicoms are in current directory
if nargin<1
    dicom_folder = pwd;
end
tags = {'TriggerTime','InStackPositionNumber','TemporalPositionIdentifier','FileName'};
%get .dcm files
[dicom_files,dicom_folder] = get_dicom_files(dicom_folder);
% get dicom header
if ~exist(fullfile(dicom_folder,'dicom_header.mat'),'file')
    fprintf('reading dicom headers ...\nThis will take a while ...\n');
    dicom_header = dicom_header_matlab(dicom_files,tags,false);
    save(fullfile(dicom_folder,'dicom_header.mat'),'dicom_header');
else
    load(fullfile(dicom_folder,'dicom_header.mat'));
end
DH = dicom_header_matlab(dicom_files{1});
num_slices = DH.LocationsInAcquisition;
num_vols = DH.NumberOfTemporalPositions;
clear DH;
if nargin<2 || isempty(vol_ind)
    vol_ind = 1:num_vols;
end
if nargin<3 || isempty(verbose)
    verbose = false;
end
% use the nearest square of num_slices as subplot size
figure_dim = calc_subplot_dim(num_slices);
% get volume labels
volume_labels = cell2mat({dicom_header.TemporalPositionIdentifier});

% draw the mosaic of each volume
counter = 1;
for v = vol_ind
    % get the handle of file names for current volume
    current_vol_idx = find(volume_labels==v);
    current_vol_slice_idx = cell2mat({dicom_header(current_vol_idx).InStackPositionNumber});
    current_vol_trigger_time = cell2mat({dicom_header(current_vol_idx).TriggerTime});
    IND = sortrows([current_vol_slice_idx(:),current_vol_idx(:),current_vol_trigger_time(:)],2);
    clear current_vol_idx current_vol_slice_idx current_vol_trigger_time;
    figure(counter);
    for n = 1:size(IND,1)
        subplot(figure_dim(1),figure_dim(2),n);
        imshow(imadjust(dicomread(dicom_files{IND(n,2)})));
        xlabel(sprintf('time:%d; slice:%d',...
            IND(n,3),IND(n,1)));
    end
    suptitle(sprintf('volume:%d',v));
    if verbose
        %print file info
        fprintf('Volume%d, Slice%d:%s\n',v,n,dicom_header.FileName);
    end
    if counter<length(vol_ind)
        disp('press any key to continue...');
        pause;
        close all;
        clc;
    end
    counter = counter + 1;
end
end

function figure_dim = calc_subplot_dim(num_slices)
if isprime(num_slices)
    %if prime, use nearest square
    figure_dim = [ceil(sqrt(num_slices)),ceil(sqrt(num_slices))];
else
    figure_dim = factor_pair(num_slices);
    [~,IND] = min(diff(figure_dim,1,2),[],1);
    figure_dim = figure_dim(IND,:);
end
end

function F = factor_pair(N)
tmp = factor(N);
F = zeros(length(tmp),2);
F(1,:) = [1,N];
for n = 1:length(tmp)-1
    F(n+1,:) = [prod(tmp(1:n)),prod(tmp(n+1:end))];
end
end

function [dicom_files,dicom_folder] = get_dicom_files(dicom_folder)
% see if current directory contains .dcm files
dicom_files = dir(fullfile(dicom_folder,'*.dcm'));
% if cannot find files, search for a folder with _dicoms
if isempty(dicom_files)
    tmp = dir(fullfile(dicom_folder,'*_dicoms'));
    % if cannot find folder, search for archives
    if isempty(tmp)
        tmp = dir(fullfile(dicom_folder,'*_dicoms.tgz'));
        if ~isempty(tmp)
            disp('decompressing archive ...');
            eval(['!tar -zxf ',fullfile(dicom_folder,tmp.name)]);
            dicom_folder = fullfile(dicom_folder,fileparts(tmp.name));
            [dicom_files,dicom_folder] = get_dicom_files(dicom_folder);
            
        else
            error('Cannot find dicom files');
        end
    else
        dicom_folder = fullfile(dicom_folder,tmp.name);
        clear tmp;
        [dicom_files,dicom_folder] = get_dicom_files(dicom_folder);
    end
else
    dicom_files = cellfun(@(x) fullfile(dicom_folder,x),{dicom_files.name},'un',0);
end
end