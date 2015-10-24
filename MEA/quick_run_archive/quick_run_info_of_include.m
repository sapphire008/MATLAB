% quick run

base_dir = 'Z:\Data\Edward\RawData\2014 September 12\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 12\';


addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\generic\');
[~, fileName] = SearchFiles(base_dir,'Data_091214_block_NMDA_AMPA*.mcd');
plot_dur = [-0.5, 0.5];
include_raws = {};
stim_channel_list = {};
event_time_stamp = [];
c = 1; % counter

%%
for m = 1:length(fileName)
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
    %% preliminary plot
    plot(time,X);%plot all the channels
    %plot stimulation current
    STIM = MEA.Digital.Channel.Data/max(MEA.Digital.Channel.Data)*max(X(:));
    hold on;
    plot(time,STIM(:)','k--','markersize',10);
    line(repmat(spkt(1,c),2,1)/fs,...
        repmat([-1;1]*max(STIM),1,length(spkt(1,c))),'LineStyle','-','Color','k');
    line(repmat(spkt(2,c),2,1)/fs,...
        repmat([-1;1]*max(STIM),1,length(spkt(2,c))),'LineStyle','-','Color','k');
    hold off;
    xlabel('time (s)'); ylabel('LFP (mV)');
    title(sprintf('Stim: %s',stim_elect));
    ButtonName = questdlg('Is the graph okay?','Graph','Yes','No','Cancel','Yes');
    switch ButtonName
        case 'Yes'
            include_raws{end+1} = filName{m};
            stim_channel_list{end+1} = stim_elect;
            c = c+1;            
        case 'No'
            spkt = spkt(:,1:c-1);
        case 'Cancel'
            break;
    end
end

%% quick test to see if all electrodes are captured
all(cellfun(@(x) ismember(x,MEA.MapInfo.channelnames),stim_channel_list))