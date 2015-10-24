% quick run
%clear all; close all; clc;
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\generic\');
addpath('Z:\Documents\Edward\scripts\MEA\');
%load('Z:\Data\Edward\Analysis\2014 September 30\datainfo.mat');

base_dir = 'Z:\Data\Edward\RawData\2014 September 30\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 30\';
plot_dur = [-0.01,0.15];
ylim = [-1,1];
fs = 10000;
c = 1; % counter
datainfo = cell(1,length(fileNames));
%% Extract Data
for n = 1:length(fileNames)%[18,37,52]
    %%
    % get event onset time
    [MEA,X] = loadMEA(fullfile(base_dir,fileNames{n}),'select',{'Electrode'},'prefer_segment',true);
    [stim_onset_ind, stim_elec, stim_elec_ind, response_elec, ...
        response_elec_ind, stim_response_amplitude, prestim_response_amplitude] = ...
        MEA_detect_stimulation(X, MEA.MapInfo.channelnames);
    % Use alternative ways to calculate 
    % get rid of stimulating electrode
    X = X(:,:,response_elec_ind);
    size_X = size(X);
    % plot the data
    figure;
    plot(reshape(X,size_X(1)*size_X(2),size_X(3)));
    hold on;
    plot(stim_onset_ind+(0:(size_X(2)-1))*size_X(1),mean(stim_response_amplitude,2), 'go');
    hold off;
    title([stim_elec,', ',num2str(stim_onset_ind)]);
    % query
    %ButtonName = questdlg('Is the event detection okay?','Event','Yes','No','Cancel','Yes');
    ButtonName = 'Yes';
    switch ButtonName
        case 'Yes'
            datainfo{n}.filename = fileNames{n};
            datainfo{n}.stim_onset_ind = stim_onset_ind;
            datainfo{n}.stim_elec = stim_elec;
            datainfo{n}.stim_elec_ind =  stim_elec_ind;
            datainfo{n}.response_elec = response_elec;
            datainfo{n}.response_elec_ind = response_elec_ind;
            datainfo{n}.stim_response_amplitude = stim_response_amplitude;
            datainfo{n}.prestim_response_amplitude = prestim_response_amplitude;
            % save intermediate
            save(fullfile(result_dir,regexprep(fileNames{n},'.mcd',sprintf('_%s.mat',stim_elec))),...
                'stim_onset_ind', 'stim_elec', 'stim_elec_ind', 'response_elec', 'response_elec_ind', 'stim_response_amplitude','prestim_response_amplitude');
        case 'No'
            %continue
        case 'Cancel'
            break;
    end
    close all; clc;
    clear stim_onset_ind stim_elec stim_elec_ind response_elec response_elec_ind stim_response_amplitude prestim_response_amplitude;
end
%save(fullfile(result_dir,'datainfo.mat'),'datainfo','-append');

%% quick test to see if all electrodes are captured
% if ~all(cellfun(@(x) ismember(x,channellist),MEA.MapInfo.channelnames))
%     disp('Not all electrodes are captured');
% else
%     disp('All electrodes are captured');
% end