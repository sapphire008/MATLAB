function pprArray = jeffBuildPPRarray(dataPathIn)
    % revised 2 Feb 2015 BWS
    % example up script 
    % Inputs: dataPath points to the main lab data folder (eg, d:/Lab Data)
    
    pprArray = {};
    dataPath = strtrim(dataPathIn);
    % add replace back slashes with forward ones TODO
    if ~strcmpi(dataPath(end),'/'), dataPath = [dataPath '/']; end
    
    dataRoot = [dataPath 'Jeff Kim/2015/01/Cell C.26Jan15']; % without the .S1.E2.dat part
    defaultThresholds = [0.6 0.6 0.6];
    traceList = {'VoltA' 'VoltC' 'VoltD'}; % traces should be listed in order
    extraStr = '';
    for ii = 1:numel(traceList)
        extraStr = [extraStr traceList{ii} ' '];
    end
    extraStr = strtrim(extraStr); % take off last space
    maxAmp = 20;
        
    % make first row
    exptPPR = helperBuildFirstRow('Temporal Neocortex', 'NeocorticalLoc1', [5 5.5], 'cclamp', 30, extraStr);
    % fill in data rows
    exptPPR = [exptPPR; helperBuildDataRow('A', 5, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 6, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 7, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 8, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 9, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 10, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 11, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 12, 1, 10, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 13, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 14, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 15, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 16, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 17, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 18, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 19, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 20, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 21, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 22, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 23, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 24, 1, 12.5, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 25, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 26, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 27, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 28, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('A', 29, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('C', 30, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('B', 31, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    exptPPR = [exptPPR; helperBuildDataRow('D', 32, 1, 15, 'CCh5', traceList, defaultThresholds, 0, maxAmp, dataRoot)];
    
    pruneIndex = [1:4 26:29]; % these indexes added after looking at resulting eggs
    for ii = 1:numel(pruneIndex)
         exptPPR{pruneIndex(ii), 4} = 0;
    end
    pprArray = exptPPR;
end

function newRow = helperBuildDataRow(stimStr, epiNum, seqNum, stimIntensity, drugStr, traceList, thresholdList, down1or0, maxAmpAllowed, dataRoot)
    % returns cell array row vector
    
    requestedFileName = [dataRoot '.S' num2str(seqNum) '.E' num2str(epiNum) '.dat'];
    zData = loadEpisodeFile(requestedFileName);
    [pathStr, fileStr, extStr] = fileparts(requestedFileName);
    outArray = jeffDetectTriples(zData, traceList, thresholdList, down1or0, maxAmpAllowed);
    numCol = 4 + numel(traceList);
    if numCol < 7, numCol = 7; end % require at least 7 columns on a PPR array 
    newRow = cell(1, numCol);
    newRow{1,1} = fileStr;
    newRow{1,2} = stimStr;
    newRow{1,3} = [drugStr 'Intensity' num2str(stimIntensity)];
    newRow{1,4} = 1;
    for ii = 1:numel(traceList)
       newRow{1,4 + ii} = outArray{ii, 1}; % get stim onset times 
    end
end

function firstRow = helperBuildFirstRow(regionStr, exptTagStr, stimTimes, clampStr, sweepDur, extraStr)
    % returns first row that goes in a PPR array for one expt
    firstRow = cell(1,7);
    firstRow{1,1} = 'Jeff';
    firstRow{1,2} = regionStr; % something like Hilus or temporal neocortex
    firstRow{1,3} = clampStr; % either cclamp or vclamp
    firstRow{1,4} = extraStr;
    firstRow{1,5} = stimTimes; % like [5 5.5]
    firstRow{1,6} = sweepDur; % in seconds
    firstRow{1,7} = exptTagStr(exptTagStr ~= ' '); % something like NeocorticalLocExpt1 -- no spaces
end