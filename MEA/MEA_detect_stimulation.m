function [stim_peak_ind, stim_elec, stim_elec_ind, response_elec, ...
    response_elec_ind, stim_response_amplitude, ...
    prestim_response_amplitude] = MEA_detect_stimulation(X, ...
    channelnames, baselinewindow, diagnostics)
% Detect stimulating electrode by finding the electrode with largest range
% of potential. Used when sampling rate is too low to record the onset and
% offset time of the stimulus.
%
%[stim_onset_ind, stim_elec, stim_elec_ind, response_elec, ...
%       response_elec_ind, stim_response_amplitude, ...
%       prestim_response_amplitude] = ...
%       MEA_detect_stimulation(X, channelnames, baselinewindow)
%
% Inputs:
%   X: [T]ime by [S]egment by [C]hannel N-D array
%   channelnames: list of channelnames, order cooresponding to Channel in X
%   baselinewindow: baseline window, specify as a vector, where position 0
%   is the stimulus onset. Default [-1:-1:-10].
%
% Outputs:
%   stim_onset_ind: stimulus onset index per segment, 1xS
%   stim_elec: stimulation electrode name, char
%   stim_elec_ind:  index of the stimulating electrode, double
%   response_elec: list of response electrodes names, cellstr
%   response_elec_ind: index of the non-stimulating elctrodes, 1x(C-1)
%   stim_response_amplitude: amplitude of potential at stim_elec_ind,
%                            Sx(C-1)
%   prestim_response_amplitude: average amplitude before stimulation (10
%                               time points, starting from -1 of stimulus
%                               onset. Sx(C-1)
% 
% Depends on loadMEA in Neuroshare library
%

% DEBUG
% fileName = 'Z:\Data\Edward\RawData\2014 September 30\Data_093014_block_GABA_NMDA_AMPA_0001.mcd';
% [MEA,X] = loadMEA(fileName); channelnames = MEA.MapInfo.channelnames;

if ismatrix(X), X = reshape(X,size(X,1),1,size(X,2)); end
if nargin<3 || isempty(baselinewindow), baselinewindow = -1:-1:-10; end
if nargin<4 || isempty(diagnostics), diagnostics = false; end
% Find the entry with largest range to be the stimulating electrode
[~,stim_elec_ind] = max(range(reshape(X,size(X,1)*size(X,2),size(X,3)),1));
stim_elec = channelnames{stim_elec_ind};
% Remove the stimulating electrode from the time series
response_elec_ind = setdiff(1:size(X,3),stim_elec_ind);
response_elec = channelnames(response_elec_ind);
%X = X(:,:,response_elec_ind);
% Detect peak for each segment using the stimulating electrode
[~,stim_peak_ind] = max(diff(abs(squeeze(X(:,:,stim_elec_ind))),1,1),[],1);
% get amplitude before stimulus
size_X = size(X);
X = reshape(X,size_X(1)*size_X(2),size_X(3));
prestim_response_amplitude = X(sub2ind(size_X(1:2),...
    bsxfun(@plus, stim_peak_ind, baselinewindow(:)),repmat(1:size_X(2),10,1)),:);
prestim_response_amplitude = squeeze(mean(reshape(prestim_response_amplitude,length(baselinewindow),size_X(2),size_X(3)),1));
% get amplitude after stimulus
stim_peak_ind = stim_peak_ind+1;
stim_response_amplitude = X(sub2ind(size_X(1:2),stim_peak_ind,1:size_X(2)),:);

% using channels other than stimulating channel to detect event
% for m = 1:size(X,2)
%     tmpX = diff(abs(squeeze(X(:,m,:))),1,1);
%     [~,IND] = max(tmpX,[],1);
%     [N,I] = hist(IND,unique(IND));
%     [~,IND_IND] = max(std(tmpX(I,:),[],2).*N(:));
%     stim_onset_ind(m) = I(IND_IND)+1;%+size(X,1)*(n-1);
%     stim_response_amplitude(m,:) = squeeze(X(stim_onset_ind(m),m,:));
%     prestim_response_amplitude(m,:) = squeeze(X(stim_onset_ind(m)-1,m,:));
% end

if ~diagnostics, return; end
% run diagnostics
stim_peak_vect = stim_peak_ind+(0:size_X(2)-1)*size_X(1);
[~, max_resp_ind] = max(abs(X(stim_peak_vect,response_elec_ind)),[],2);
max_resp_ind = response_elec_ind(max_resp_ind);% which electrode
max_resp_ind = sub2ind(size(stim_response_amplitude),1:size(stim_response_amplitude,1),max_resp_ind);
plot(X(:,response_elec_ind));
hold on;
plot(stim_peak_vect, stim_response_amplitude(max_resp_ind),'ro');
text(stim_peak_vect, stim_response_amplitude(max_resp_ind)*1.1, num2str(stim_peak_vect(:)));
hold off;
xlabel('Index');
ylabel('Voltage (mV)');
title(stim_elec);
end