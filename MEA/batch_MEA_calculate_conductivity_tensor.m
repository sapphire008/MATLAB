% batch calculate MEA conductivity tensor
data_dir = 'Z:\Data\Edward\RawData\2014 September 12\';
data_info_dir = 'Z:\Data\Edward\Analysis\2014 September 12\datainfo.mat';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 12\';

solve_methods = {'fminsearch','fminunc','fsolve','lsq'};

% load necessary parameters and add appropriate libraries
load(data_info_dir,'data_info');
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\MEA\');
addpath('Z:\Documents\Edward\scripts\generic\');

[channel_list,~,IC] = unique({data_info.StimulationChannel});

for n = 1:length(channel_list)
    stim_elect = channel_list{n};
    % aggregate data
    U = [];
    I = [];
    % get current and voltage
    index = find(IC==n);
    for k = 1:length(index)
        [MEA,X] = loadMEA(fullfile(data_dir,data_info(index(k)).DataFileName),...
            'stream_channel',data_info(index(k)).EventOnsetIndex+[0,1]);
        % calculate the increase in activity
        U =  cat(2,U,diff(X,1)');
        I = [I,data_info(index(k)).StimulationAmplitude_uA*1E-3];
    end
    % get current density
    r = 15E-3;%radius of electrode mm
    I = I/(pi*r^2);%current density: mA/mm^2
    % get maps
    MAP = flipud(MEA.MapInfo.coord)';
    XY_I = flipud(MEA.MapInfo.coord(:,find(ismember(MEA.MapInfo.channelnames,stim_elect))))';
    
    % calculate the tensor via different methods
    for m = 1:length(solve_methods)
        [Sigma, W, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor(U,I,...
            MAP,XY_I,'method',solve_methods{m},'diagnostics',true);
        
        saveas(gcf,fullfile(result_dir,[stim_elect,'_W_and_sigma_distribution_',solve_methods{m},'.fig']));
        close(gcf);
    end
end