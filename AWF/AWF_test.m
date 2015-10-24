function AWF_constructor(savedir)
if nargin<1, savedir = 'D:\AWF.dat'; end
ts = 0.1; % ms
factor = 3.2; % ITC18 scaling factor

% Protcol specification
Steps(1).window = [0, 250]; %ms
Steps(1).amp = 0; %mV
Steps(2).window = [250, 500]; %ms
Steps(2).amp = amp; % mV
Steps(3).window = [500, 750]; %ms
Steps(3).amp = 0; % mV

% Construct the waveform
waveform = [];
for n = 1:length(Steps)
    waveform = [waveform, factor * Steps(n).amp*ones(1, length(Steps(n).window(1):ts:Steps(n).window(2))-1)];
end
% Write protocol to binary file
fid = fopen(savedir,'w');
%fwrite(fid, waveform, 'float64');
fprintf(fid, '%.2f\r\n', waveform);
fclose(fid);

end
%copyfile('D:\AWF.dat','C:\AWF.dat','f')