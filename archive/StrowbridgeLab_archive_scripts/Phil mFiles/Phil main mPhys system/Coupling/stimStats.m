function [dataVals pValues]= stimStats(j, i)
% looks for significant differences in PSPdata
% return structure is of the form (fromCell, toCell, PSPdirection, stat) where stat =
% significance of the connection
% significance of difference in Amps
% significance of differences in Taus
% significance of differences in Latencies
% significance of differences in Decays
% significance of differences in Frequencies

if findstr(get(gcf, 'name'), 'Coupling') > 1
    error('Must first select a coupling figure')
end
tempData = get(gcf, 'userData');
PSPdata = tempData{4};
numProcessed = tempData{2};
numControlWindows = tempData{6};
dataVals = zeros(2,18);
pValues = ones(2,6);
PSPdata(PSPdata< -100000) = 0;
j = j * 2 - 1;

% look for differences between first and second spikes for any significant
% spikes
    % check up PSPs
    upPSPsFirst = find(PSPdata(i, j, 3, :) > 0);
    upPSPsSecond = find(PSPdata(i, j + 1, 3, :) > 0);
    pValues(1,  1) = chiTest([length(upPSPsFirst) + length(upPSPsSecond) numProcessed(j) * 2; length(find(PSPdata(i, end, 3, :) > 0)) numProcessed(size(PSPdata, 2) - 1 + i) * numControlWindows]);
    % compare the two stims' amplitudes
    pValues(1,  2) = TTestParam([mean(PSPdata(i, j, 3, upPSPsFirst)); mean(PSPdata(i, j + 1, 3, upPSPsSecond))], [std(PSPdata(i, j, 3, upPSPsFirst)); std(PSPdata(i, j + 1, 3, upPSPsSecond))], [length(PSPdata(i, j, 3, upPSPsFirst)); length(PSPdata(i, j + 1, 3, upPSPsSecond))]);
    % compare the two stims' taus
    pValues(1,  3) = TTestParam([mean(PSPdata(i, j, 4, upPSPsFirst)); mean(PSPdata(i, j + 1, 4, upPSPsSecond))], [std(PSPdata(i, j, 4, upPSPsFirst)); std(PSPdata(i, j + 1, 4, upPSPsSecond))], [length(PSPdata(i, j, 4, upPSPsFirst)); length(PSPdata(i, j + 1, 4, upPSPsSecond))]);
    % compare the two stims' latencys
    pValues(1,  4) = TTestParam([mean(PSPdata(i, j, 5, upPSPsFirst)); mean(PSPdata(i, j + 1, 5, upPSPsSecond))], [std(PSPdata(i, j, 5, upPSPsFirst)); std(PSPdata(i, j + 1, 5, upPSPsSecond))], [length(PSPdata(i, j, 5, upPSPsFirst)); length(PSPdata(i, j + 1, 5, upPSPsSecond))]);
    % compare the two stims' decays
    pValues(1,  5) = TTestParam([mean(PSPdata(i, j, 6, upPSPsFirst)); mean(PSPdata(i, j + 1, 6, upPSPsSecond))], [std(PSPdata(i, j, 6, upPSPsFirst)); std(PSPdata(i, j + 1, 6, upPSPsSecond))], [length(PSPdata(i, j, 6, upPSPsFirst)); length(PSPdata(i, j + 1, 6, upPSPsSecond))]);
    % compare the two stims' frequencies
    pValues(1,  6) = chiTest([length(upPSPsFirst) numProcessed(j); length(upPSPsSecond) numProcessed(j + 1)]);
    if nargout == 0
        disp(['Cell ' num2str((j + 1)/2) ' onto cell ' num2str(i) ' upPSP: p = ' num2str(pValues(1,  1))]);
        
            disp(['    Amps: p = ' num2str(pValues(1,  2))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 3, upPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 3, upPSPsFirst))) ' mV'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 3, upPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 3, upPSPsSecond))) ' mV'])
            
            disp(['    Rise Times: p = ' num2str(pValues(1,  3))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 4, upPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 4, upPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 4, upPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 4, upPSPsSecond))) ' msec'])                    

            disp(['    Latencies: p = ' num2str(pValues(1,  4))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 5, upPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 5, upPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 5, upPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 5, upPSPsSecond))) ' msec'])                    

            disp(['    Decays: p = ' num2str(pValues(1,  5))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 6, upPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 6, upPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 6, upPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 6, upPSPsSecond))) ' msec'])     
            
            disp(['    Hit rate: p = ' num2str(pValues(1,  6))]);
            disp(['        Mean of First = ' num2str(100 * length(upPSPsFirst) / numProcessed(j)) '%'])
            disp(['        Mean of Second = ' num2str(100 * length(upPSPsSecond) / numProcessed(j + 1)) '%'])  
    else
        dataVals(1,1) = mean(PSPdata(i, j, 3, upPSPsFirst));
        dataVals(1,2) = std(PSPdata(i, j, 3, upPSPsFirst));
        dataVals(1,3) = mean(PSPdata(i, j + 1, 3, upPSPsSecond));
        dataVals(1,4) = std(PSPdata(i, j + 1, 3, upPSPsSecond));
        dataVals(1,5) = mean(PSPdata(i, j, 4, upPSPsFirst));
        dataVals(1,6) = std(PSPdata(i, j, 4, upPSPsFirst));
        dataVals(1,7) = mean(PSPdata(i, j + 1, 4, upPSPsSecond));
        dataVals(1,8) = std(PSPdata(i, j + 1, 4, upPSPsSecond));
        dataVals(1,9) = mean(PSPdata(i, j, 5, upPSPsFirst));
        dataVals(1,10) = std(PSPdata(i, j, 5, upPSPsFirst));
        dataVals(1,11) = mean(PSPdata(i, j + 1, 5, upPSPsSecond));
        dataVals(1,12) = std(PSPdata(i, j + 1, 5, upPSPsSecond));
        dataVals(1,13) = mean(PSPdata(i, j, 6, upPSPsSecond));
        dataVals(1,14) = std(PSPdata(i, j, 6, upPSPsSecond));        
        dataVals(1,15) = mean(PSPdata(i, j + 1, 6, upPSPsSecond));
        dataVals(1,16) = std(PSPdata(i, j + 1, 6, upPSPsSecond));
        dataVals(1,17) = length(upPSPsFirst) / numProcessed(j);
        dataVals(1,18) = length(upPSPsSecond) / numProcessed(j + 1);
    end

    % check down PSPs
    downPSPsFirst = find(PSPdata(i, j, 3, :) < 0);
    downPSPsSecond = find(PSPdata(i, j + 1, 3, :) < 0);
    pValues(2,  1) = chiTest([length(downPSPsFirst) + length(downPSPsSecond) numProcessed(j) * 2; length(find(PSPdata(i, end, 3, :) < 0)) numProcessed(size(PSPdata, 2) - 1 + i) * numControlWindows]);
    % compare the two stims' amplitudes
    pValues(2,  2) = TTestParam([mean(PSPdata(i, j, 3, downPSPsFirst)); mean(PSPdata(i, j + 1, 3, downPSPsSecond))], [std(PSPdata(i, j, 3, downPSPsFirst)); std(PSPdata(i, j + 1, 3, downPSPsSecond))], [length(PSPdata(i, j, 3, downPSPsFirst)); length(PSPdata(i, j + 1, 3, downPSPsSecond))]);
    % compare the two stims' taus
    pValues(2,  3) = TTestParam([mean(PSPdata(i, j, 4, downPSPsFirst)); mean(PSPdata(i, j + 1, 4, downPSPsSecond))], [std(PSPdata(i, j, 4, downPSPsFirst)); std(PSPdata(i, j + 1, 4, downPSPsSecond))], [length(PSPdata(i, j, 4, downPSPsFirst)); length(PSPdata(i, j + 1, 4, downPSPsSecond))]);
    % compare the two stims' latencys
    pValues(2,  4) = TTestParam([mean(PSPdata(i, j, 5, downPSPsFirst)); mean(PSPdata(i, j + 1, 5, downPSPsSecond))], [std(PSPdata(i, j, 5, downPSPsFirst)); std(PSPdata(i, j + 1, 5, downPSPsSecond))], [length(PSPdata(i, j, 5, downPSPsFirst)); length(PSPdata(i, j + 1, 5, downPSPsSecond))]);
    % compare the two stims' decays
    pValues(2,  5) = TTestParam([mean(PSPdata(i, j, 6, downPSPsFirst)); mean(PSPdata(i, j + 1, 6, downPSPsSecond))], [std(PSPdata(i, j, 6, downPSPsFirst)); std(PSPdata(i, j + 1, 6, downPSPsSecond))], [length(PSPdata(i, j, 6, downPSPsFirst)); length(PSPdata(i, j + 1, 6, downPSPsSecond))]);
    % compare the two stims' frequencies
    pValues(2,  6) = chiTest([length(downPSPsFirst) numProcessed(j); length(downPSPsSecond) numProcessed(j + 1)]);
    if nargout == 0
        disp(['Cell ' num2str((j + 1)/2) ' onto cell ' num2str(i) ' downPSP: p = ' num2str(pValues(2,  1))]);

            disp(['    Amps: p = ' num2str(pValues(2,  2))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 3, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 3, downPSPsFirst))) ' mV'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 3, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 3, downPSPsSecond))) ' mV'])

            disp(['    Rise Times: p = ' num2str(pValues(2,  3))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 4, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 4, downPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 4, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 4, downPSPsSecond))) ' msec'])                    

            disp(['    Latencies: p = ' num2str(pValues(2,  4))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 5, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 5, downPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 5, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 5, downPSPsSecond))) ' msec'])                    

            disp(['    Decays: p = ' num2str(pValues(2,  5))]);
            disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 6, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 6, downPSPsFirst))) ' msec'])
            disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 6, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 6, downPSPsSecond))) ' msec'])                    
            
            disp(['    Hit rate: p = ' num2str(pValues(2,  6))]);
            disp(['        Mean of First = ' num2str(100 * length(downPSPsFirst) / numProcessed(j)) '%'])
            disp(['        Mean of Second = ' num2str(100 * length(downPSPsSecond) / numProcessed(j + 1)) '%'])     
    else
        dataVals(2,1) = mean(PSPdata(i, j, 3, downPSPsFirst));
        dataVals(2,2) = std(PSPdata(i, j, 3, downPSPsFirst));
        dataVals(2,3) = mean(PSPdata(i, j + 1, 3, downPSPsSecond));
        dataVals(2,4) = std(PSPdata(i, j + 1, 3, downPSPsSecond));
        dataVals(2,5) = mean(PSPdata(i, j, 4, downPSPsFirst));
        dataVals(2,6) = std(PSPdata(i, j, 4, downPSPsFirst));
        dataVals(2,7) = mean(PSPdata(i, j + 1, 4, downPSPsSecond));
        dataVals(2,8) = std(PSPdata(i, j + 1, 4, downPSPsSecond));
        dataVals(2,9) = mean(PSPdata(i, j, 5, downPSPsFirst));
        dataVals(2,10) = std(PSPdata(i, j, 5, downPSPsFirst));
        dataVals(2,11) = mean(PSPdata(i, j + 1, 5, downPSPsSecond));
        dataVals(2,12) = std(PSPdata(i, j + 1, 5, downPSPsSecond));
        dataVals(2,13) = mean(PSPdata(i, j + 1, 6, downPSPsSecond));
        dataVals(2,14) = std(PSPdata(i, j + 1, 6, downPSPsSecond));
        dataVals(2,15) = mean(PSPdata(i, j + 1, 6, downPSPsSecond));
        dataVals(2,16) = std(PSPdata(i, j + 1, 6, downPSPsSecond));
        dataVals(2,17) = length(downPSPsFirst) / numProcessed(j);
        dataVals(2,18) = length(downPSPsSecond) / numProcessed(j + 1);
    end            
end