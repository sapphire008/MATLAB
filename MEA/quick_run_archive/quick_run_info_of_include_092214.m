% quick run
clear all; close all; clc;
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\generic\');

base_dir = 'Z:\Data\Edward\RawData\2014 September 19\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 19\';
[~, fileName] = SearchFiles(base_dir,'Data_091914_block_NMDA_AMPA*.mcd');
plot_dur = [-0.01,0.15];
ylim = [-0.5,5];
%include_raws = {};
stim_channel_list = cell(1,length(fileName));
event_time_stamp = cell(1,length(fileName));
c = 1; % counter
%% Extract Data
for n = 53:length(fileName)%[18,37,52]
    %%
    % Get Trigger event onset
    MEA_tmp = loadMEA(fullfile(base_dir,fileName{n}),'select',{'Analog',...
        'Digital','Trigger'});
    MEA = loadMEA(fullfile(base_dir, fileName{n}),'info',true);
    MEA.Digital = MEA_tmp.Digital;
    MEA.Trigger = MEA_tmp.Trigger;
    MEA.Analog = MEA_tmp.Analog;
    clear MEA_tmp;
    event_time = find(MEA.Digital.Channel.Data);
    event_time_stamp{n} = event_time;
    % Get other info
    fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
    % index range of data to get around the stims
    ind_range = bsxfun(@plus,plot_dur*fs,event_time(1:2:end))';
    % find out which electrode is being stimulated during the trial, at the
    % same time, find out the spike timing/index
    X = zeros(size(ind_range,2),ind_range(2,1)-ind_range(1,1)+1,120);%event x time x channel
    for k = 1:size(ind_range,2)%event
        [~,X(k,:,:)] = loadMEA(fullfile(base_dir, fileName{n}),...
            'stream_channel',ind_range(:,k)','select',{'Electrode'});
    end
    X_range = range(reshape(X,size(X,1)*size(X,2), size(X,3)),1);
    [~,stim_channel] = max(X_range);
    stim_channel = MEA.MapInfo.channelnames{stim_channel};
    stim_channel_list{n} = stim_channel;
    % find spike onset time
    [SPIKE_V,SPIKE_T] = max(X,[],2);
    SPIKE_V = squeeze(SPIKE_V);
    SPIKE_T = bsxfun(@plus,squeeze(SPIKE_T), ind_range(1,:)');
    % save basic info for each file
    save(fullfile(base_dir,regexprep(fileName{n},'.mcd',['_',stim_channel,'.mat'])),'X','MEA','X_range',...
        'stim_channel','event_time','ind_range','SPIKE_V','SPIKE_T');
    clear X SPIKE_V SPIKE_T MEA;
end

%% quick test to see if all electrodes are captured
if ~all(cellfun(@(x) ismember(x,stim_channel_list),MEA.MapInfo.channelnames))
    disp('Not all electrodes are captured');
else
    disp('All electrodes are captured');
end