% quick run
clear all; close all; clc;
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\generic\');

base_dir = 'Z:\Data\Edward\RawData\2014 September 12\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 12\';
[~, fileName] = SearchFiles(base_dir,'Data_091214_block_NMDA_AMPA*.mcd');
plot_dur = -2:1:4;
ylim = [-0.5,5];
%include_raws = {};
stim_channel_list = {};
event_time_stamp = [];
c = 1; % counter
A = [32,34,39,40,42,52,57,62,70];
%%
for m = A
    %%
    [MEA,X] = loadMEA(fullfile(base_dir,fileName{m}));
    fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
    nT = size(X,1);
    dt = 1/fs;          % time step
    time = (0:nT-1)/fs; % time vector
    % find out which electrode is being stimulated during the trial
    [~,stim_elec_ind] = max(range(X,1));
    stim_elect = MEA.MapInfo.channelnames{stim_elec_ind};
    % Event detector: up transient 
    [~,event_onset_ind] = max(diff(X,1,1));
    event_onset_ind = mode(event_onset_ind);
    % preliminary plot
    %plot(plot_dur+event_onset_ind,X(plot_dur+event_onset_ind,:));
    %hold on;
    %plot((event_onset_ind+1)*ones(1,size(X,2)), X((event_onset_ind+1)*ones(1,size(X,2)),:),'ro');
    %set(gca,'ylim',ylim);
    %hold off;
    plot(X);
    xlabel('time (s)'); ylabel('LFP (mV)');
    title(sprintf('Stim: %s',stim_elect));
%     ButtonName = questdlg('Is the graph okay?','Graph','Yes','No','Cancel','Yes');
%     %ButtonName = 'Yes';
%     switch ButtonName
%         case 'Yes'
%             %include_raws{end+1} = fileName{m};
%             stim_channel_list{end+1} = stim_elect;
%             event_time_stamp = [event_time_stamp,event_onset_ind];
%             c = c+1;            
%         case 'No'
%             %
%         case 'Cancel'
%             break;
%     end
break
end

%% quick test to see if all electrodes are captured
if ~all(cellfun(@(x) ismember(x,stim_channel_list),MEA.MapInfo.channelnames))
    disp('Not all electrodes are captured');
else
    disp('All electrodes are captured');
end