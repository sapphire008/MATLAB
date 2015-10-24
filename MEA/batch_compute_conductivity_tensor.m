% Batch compute conductivity tensor 10/02/14
clear all; close all; clc
base_dir = 'Z:\Data\Edward\RawData\2014 September 30\';
result_dir = 'Z:\Data\Edward\Analysis\2014 September 30\';
addpath('Z:\Documents\Edward\scripts\NeuroShare\');
addpath('Z:\Documents\Edward\scripts\MEA\');
addpath('Z:\Documents\Edward\scripts\generic\');
load(fullfile(result_dir,'datainfo_100314.mat'));


J = [-5,5,-4,4,-3,3,-2,2,-1,1]; %J = abs(J);
MAP = MapInfo.coord';
PITCH = 0.2;
badelectrodes = 'G6';

worksheet_header =  {'Electrode', 'Tensor', 'fval', 'eigenvector', 'eigenvalues', 'stdSigma', 'numNN'};

worksheet = cell(length(datainfo)+1, length(worksheet_header));
worksheet(1,:) = worksheet_header;

for n = [44,54,56,65:67]%1:length(datainfo)
    % find out necessary data and parameters
    XY_J = MapInfo.coord(:,datainfo(n).stim_elec_ind)';
    U = (datainfo(n).stim_response_amplitude - datainfo(n).prestim_response_amplitude)';
    %U = abs(U);
    % calculate tensor
    [Sigma, S, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor(U,...
        J,PITCH,XY_J,MAP,'NN',2,'channelnames',MEA.MapInfo.channelnames,...
        'badelectrodes',badelectrodes);
    
    % save outputs
    saveas(figure(1),fullfile(result_dir,regexprep(datainfo(n).filename,'.mcd',['_',datainfo(n).stim_elec,'_conductance.fig'])));
    saveas(figure(2),fullfile(result_dir,regexprep(datainfo(n).filename,'.mcd',['_',datainfo(n).stim_elec,'_tensor.fig'])));
    save(fullfile(result_dir, regexprep(datainfo(n).filename,'.mcd',['_',datainfo(n).stim_elec,'.mat'])), 'Sigma','S','DIAGNOSTICS','SUMMARY');
    close all;
    
    % write to data sheet
    %load(fullfile(result_dir, 'tensor_calculated_with_W', regexprep(datainfo(n).filename,'.mcd',['_',datainfo(n).stim_elec,'.mat'])));
    worksheet{n+1, 1} = datainfo(n).stim_elec;
    worksheet{n+1, 2} = mat2str(median(Sigma,3));
    worksheet{n+1, 3} = SUMMARY.fvals;
    [V, D] = eig(median(Sigma,3));
    worksheet{n+1, 4} = mat2str(V);
    worksheet{n+1, 5} = mat2str(D);
    worksheet{n+1, 6} = mat2str(std(Sigma,1,3));
    worksheet{n+1, 7} = SUMMARY.nearest_neighbor_properties.count;
    clear Sigma S DIAGNOSTICS SUMMARY U XY_J;
end
%cell2csv(fullfile(result_dir, 'Tensor_summary.csv'), worksheet, ',');

%% clean up
% convert all the previous strings to matrices
K = worksheet(2:end,2:6);
for n = 1:numel(K)
    if ischar(K{n})
        K{n} = str2num(K{n});
    end
end
worksheet(2:end,2:6) = K;
subworksheet = worksheet([1;1+find(strcmpi(worksheet(2:end,8),'Yes'))],:);
% convert to structure
S = cell2struct(subworksheet(2:end,:),subworksheet(1,:),2);
% Get Sigma
Sigma = cell2mat(subworksheet(2:end,2)');
Sigma = reshape(Sigma,2,2,size(Sigma,2)/2);
% get XY
XY = translate_electrode_label(subworksheet(2:end,1),MAP,channelnames);

save('worksheet_summary.mat','worksheet','subworksheet','S','Sigma','XY', 'MAP','channelnames');


