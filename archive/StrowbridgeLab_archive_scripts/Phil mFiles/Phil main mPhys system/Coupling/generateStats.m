function pValues = generateStats
% looks for significant differences in PSPdata
% return structure is of the form (fromCell, toCell, PSPdirection, stat) where stat =
% significance of the connection
% significance of difference in Amps
% significance of differences in Taus
% significance of differences in Latencies
% significance of differences in Frequencies

if length(findstr(get(gcf, 'name'), 'Coupling')) < 1 || findstr(get(gcf, 'name'), 'Coupling') ~= 1
    error('Must first select a coupling figure')
end
tempData = get(gcf, 'userData');
PSPdata = tempData{4};
numProcessed = tempData{2};
numControlWindows = tempData{6};

% look for differences between first and second spikes for any significant
% spikes
for i = 1:size(PSPdata, 1)
    for j = 1:2:size(PSPdata, 2) - 1
        if i ~= (j + 1) / 2
            % check up PSPs
            % check down PSPs
            downPSPsFirst = find(PSPdata(i, j, 3, :) > 0);
            downPSPsSecond = find(PSPdata(i, j + 1, 3, :) > 0);
            pValues((j + 1)/ 2, i, 2, 1) = chiTest([length(downPSPsFirst) + length(downPSPsSecond) numProcessed(j) + numProcessed(j + 1); length(find(PSPdata(i, end, 3, :) > 0)) numProcessed(i + size(PSPdata, 2) - 1) * numControlWindows]);
            % compare the two stims' amplitudes
            pValues((j + 1)/ 2, i, 2, 2) = TTestParam([mean(PSPdata(i, j, 3, downPSPsFirst)); mean(PSPdata(i, j + 1, 3, downPSPsSecond))], [std(PSPdata(i, j, 3, downPSPsFirst)); std(PSPdata(i, j + 1, 3, downPSPsSecond))], [length(PSPdata(i, j, 3, downPSPsFirst)); length(PSPdata(i, j + 1, 3, downPSPsSecond))]);
            % compare the two stims' taus
            pValues((j + 1)/ 2, i, 2, 3) = TTestParam([mean(PSPdata(i, j, 4, downPSPsFirst)); mean(PSPdata(i, j + 1, 4, downPSPsSecond))], [std(PSPdata(i, j, 4, downPSPsFirst)); std(PSPdata(i, j + 1, 4, downPSPsSecond))], [length(PSPdata(i, j, 4, downPSPsFirst)); length(PSPdata(i, j + 1, 4, downPSPsSecond))]);
            % compare the two stims' latencys
            pValues((j + 1)/ 2, i, 2, 4) = TTestParam([mean(PSPdata(i, j, 5, downPSPsFirst)); mean(PSPdata(i, j + 1, 5, downPSPsSecond))], [std(PSPdata(i, j, 5, downPSPsFirst)); std(PSPdata(i, j + 1, 5, downPSPsSecond))], [length(PSPdata(i, j, 5, downPSPsFirst)); length(PSPdata(i, j + 1, 5, downPSPsSecond))]);
            % compare the two stims' decays
            pValues((j + 1)/ 2, i, 2, 5) = TTestParam([mean(PSPdata(i, j, 6, downPSPsFirst)); mean(PSPdata(i, j + 1, 6, downPSPsSecond))], [std(PSPdata(i, j, 6, downPSPsFirst)); std(PSPdata(i, j + 1, 6, downPSPsSecond))], [length(PSPdata(i, j, 6, downPSPsFirst)); length(PSPdata(i, j + 1, 6, downPSPsSecond))]);
            % compare the two stims' frequencies
            pValues((j + 1)/ 2, i, 2, 6) = chiTest([length(downPSPsFirst) numProcessed(j); length(downPSPsSecond) numProcessed(j + 1)]);
            if nargout == 0 && (pValues((j + 1)/ 2, i, 2, 1) < 0.05) && ((length(downPSPsFirst) + length(downPSPsSecond)) * numControlWindows / 2 > length(find(PSPdata(i, end, 3, :) > 0)))
                disp(['Cell ' num2str((j + 1)/2) ' onto cell ' num2str(i) ' upPSP: p = ' num2str(pValues((j + 1)/ 2, i, 2, 1))]);
                if pValues((j + 1)/ 2, i, 2, 2) < 0.05
                    disp(['    Amps: p = ' num2str(pValues((j + 1)/ 2, i, 2, 2))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 3, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 3, downPSPsFirst))) ' mV'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 3, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 3, downPSPsSecond))) ' mV'])
                end
                if pValues((j + 1)/ 2, i, 2, 3) < 0.05
                    disp(['    Taus: p = ' num2str(pValues((j + 1)/ 2, i, 2, 3))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 4, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 4, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 4, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 4, downPSPsSecond))) ' msec'])                    
                end
                if pValues((j + 1)/ 2, i, 2, 4) < 0.05
                    disp(['    Latencies: p = ' num2str(pValues((j + 1)/ 2, i, 2, 4))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 5, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 5, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 5, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 5, downPSPsSecond))) ' msec'])                    
                end
                if pValues((j + 1)/ 2, i, 2, 5) < 0.05
                    disp(['    Decays: p = ' num2str(pValues((j + 1)/ 2, i, 2, 5))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 6, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 6, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 6, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 6, downPSPsSecond))) ' msec'])                    
                end
                if pValues((j + 1)/ 2, i, 2, 6) < 0.05
                    disp(['    Hit rate: p = ' num2str(pValues((j + 1)/ 2, i, 2, 6))]);
                    disp(['        Mean of First = ' num2str(100 * length(downPSPsFirst) / numProcessed(j)) '%'])
                    disp(['        Mean of Second = ' num2str(100 * length(downPSPsSecond) / numProcessed(j + 1)) '%'])                              
                end
            end            
            
            % check down PSPs
            downPSPsFirst = find(PSPdata(i, j, 3, :) < 0);
            downPSPsSecond = find(PSPdata(i, j + 1, 3, :) < 0);
            pValues((j + 1)/ 2, i, 2, 1) = chiTest([length(downPSPsFirst) + length(downPSPsSecond) numProcessed(j) + numProcessed(j + 1); length(find(PSPdata(i, end, 3, :) < 0)) numProcessed(i + size(PSPdata, 2) - 1) * numControlWindows]);
            % compare the two stims' amplitudes
            pValues((j + 1)/ 2, i, 2, 2) = TTestParam([mean(PSPdata(i, j, 3, downPSPsFirst)); mean(PSPdata(i, j + 1, 3, downPSPsSecond))], [std(PSPdata(i, j, 3, downPSPsFirst)); std(PSPdata(i, j + 1, 3, downPSPsSecond))], [length(PSPdata(i, j, 3, downPSPsFirst)); length(PSPdata(i, j + 1, 3, downPSPsSecond))]);
            % compare the two stims' taus
            pValues((j + 1)/ 2, i, 2, 3) = TTestParam([mean(PSPdata(i, j, 4, downPSPsFirst)); mean(PSPdata(i, j + 1, 4, downPSPsSecond))], [std(PSPdata(i, j, 4, downPSPsFirst)); std(PSPdata(i, j + 1, 4, downPSPsSecond))], [length(PSPdata(i, j, 4, downPSPsFirst)); length(PSPdata(i, j + 1, 4, downPSPsSecond))]);
            % compare the two stims' latencys
            pValues((j + 1)/ 2, i, 2, 4) = TTestParam([mean(PSPdata(i, j, 5, downPSPsFirst)); mean(PSPdata(i, j + 1, 5, downPSPsSecond))], [std(PSPdata(i, j, 5, downPSPsFirst)); std(PSPdata(i, j + 1, 5, downPSPsSecond))], [length(PSPdata(i, j, 5, downPSPsFirst)); length(PSPdata(i, j + 1, 5, downPSPsSecond))]);
            % compare the two stims' decays
            pValues((j + 1)/ 2, i, 2, 5) = TTestParam([mean(PSPdata(i, j, 6, downPSPsFirst)); mean(PSPdata(i, j + 1, 6, downPSPsSecond))], [std(PSPdata(i, j, 6, downPSPsFirst)); std(PSPdata(i, j + 1, 6, downPSPsSecond))], [length(PSPdata(i, j, 6, downPSPsFirst)); length(PSPdata(i, j + 1, 6, downPSPsSecond))]);
            % compare the two stims' frequencies
            pValues((j + 1)/ 2, i, 2, 6) = chiTest([length(downPSPsFirst) numProcessed(j); length(downPSPsSecond) numProcessed(j + 1)]);
            if nargout == 0 && (pValues((j + 1)/ 2, i, 2, 1) < 0.05) && ((length(downPSPsFirst) + length(downPSPsSecond)) * numControlWindows / 2 > length(find(PSPdata(i, end, 3, :) < 0)))
                disp(['Cell ' num2str((j + 1)/2) ' onto cell ' num2str(i) ' downPSP: p = ' num2str(pValues((j + 1)/ 2, i, 2, 1))]);
                if pValues((j + 1)/ 2, i, 2, 2) < 0.05
                    disp(['    Amps: p = ' num2str(pValues((j + 1)/ 2, i, 2, 2))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 3, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 3, downPSPsFirst))) ' mV'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 3, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 3, downPSPsSecond))) ' mV'])
                end
                if pValues((j + 1)/ 2, i, 2, 3) < 0.05
                    disp(['    Taus: p = ' num2str(pValues((j + 1)/ 2, i, 2, 3))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 4, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 4, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 4, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 4, downPSPsSecond))) ' msec'])                    
                end
                if pValues((j + 1)/ 2, i, 2, 4) < 0.05
                    disp(['    Latencies: p = ' num2str(pValues((j + 1)/ 2, i, 2, 4))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 5, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 5, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 5, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 5, downPSPsSecond))) ' msec'])                    
                end
                if pValues((j + 1)/ 2, i, 2, 5) < 0.05
                    disp(['    Decays: p = ' num2str(pValues((j + 1)/ 2, i, 2, 5))]);
                    disp(['        Mean of First = ' num2str(mean(PSPdata(i, j, 6, downPSPsFirst))) ' ' char(177) ' ' num2str(std(PSPdata(i, j, 6, downPSPsFirst))) ' msec'])
                    disp(['        Mean of Second = ' num2str(mean(PSPdata(i, j + 1, 6, downPSPsSecond))) ' ' char(177) ' ' num2str(std(PSPdata(i, j + 1, 6, downPSPsSecond))) ' msec'])                    
                end                
                if pValues((j + 1)/ 2, i, 2, 6) < 0.05
                    disp(['    Hit rate: p = ' num2str(pValues((j + 1)/ 2, i, 2, 6))]);
                    disp(['        Mean of First = ' num2str(100 * length(downPSPsFirst) / numProcessed(j)) '%'])
                    disp(['        Mean of Second = ' num2str(100 * length(downPSPsSecond) / numProcessed(j + 1)) '%'])                              
                end
            end            
        end
    end
end