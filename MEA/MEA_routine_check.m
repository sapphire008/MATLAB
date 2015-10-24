function [spkt,channelname,include_exclude] = MEA_routine_check(fileName, plot_dur, interactive)
if nargin<3, interactive = false; end

% Load Data
[MEA,X]=loadMEA(fileName);
% get some static parameter
fs = MEA.Electrode.Channel.Info(1).SampleRate;% sampling frequency in Hz
% Stimulation Event
spkt(1,1) = max([find(MEA.Digital.Channel.Data,1)+plot_dur(1)*fs,1]);
spkt(2,1) = min([find(MEA.Digital.Channel.Data,1)+plot_dur(2)*fs,size(X,1)]);
% Detect electrode is being stimulated during the trial
[~,stim_elec_ind] = max(range(X,1));
channelname = MEA.MapInfo.channelnames{stim_elec_ind};

% skip the interactive step if not speicified
if ~interactive
    include_exclude = 1;
    return;
end
nT = size(X,1);% number of time points
time = (0:nT-1)/fs; % time vector
% plot and ask the user to accept/reject the graph
plot(time,X);%plot all the channels
%plot stimulation current
STIM = MEA.Digital.Channel.Data/max(MEA.Digital.Channel.Data)*max(X(:));
hold on;
plot(time,STIM(:)','k--','markersize',10);
line(repmat(spkt(1,1),2,1)/fs,...
    repmat([-1;1]*max(STIM),1,length(spkt(1,1))),'LineStyle','-','Color','k');
line(repmat(spkt(2,1),2,1)/fs,...
    repmat([-1;1]*max(STIM),1,length(spkt(2,1))),'LineStyle','-','Color','k');
hold off;
xlabel('time (s)'); ylabel('LFP (mV)');
title(sprintf('Stim: %s',stim_elect));
ButtonName = questdlg('Is the graph okay?','Graph','Yes','No','Cancel','Yes');
switch ButtonName
    case 'Yes'
        include_exclude = 1;
    case 'No'
        include_exclude = 0;
        channelname = [];
        spkt = [];
    case 'Cancel'
        include_exclude = [];
end
end
