function outText = evaluateBonusText(protocol)
% short and long concentrations are the same
outText = '';

bonusText = getappdata(0, 'bonusText');
if ~isstruct(bonusText)
    return
end
ampNum = 1;

if bonusText.ShortFileName
    outText = [outText protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end) ' '];
end

if bonusText.FullFileName
    outText = [outText protocol.fileName ' '];
end

if bonusText.BaselineVm
    outText = [outText 'Init:' sprintf('%0.1f', protocol.startingValues(whichChannel(protocol, ampNum, 'V'))) 'mV '];
end

if bonusText.BaselineIm
    outText = [outText 'Init:' sprintf('%0.0f', protocol.startingValues(whichChannel(protocol, ampNum, 'I'))) 'pA '];
end

if bonusText.WCTime
    outText = [outText 'WCtime:' sec2time(protocol.cellTime) ' '];
end

if bonusText.StepAmplitude
    steps = findSteps(protocol, ampNum);
    outText = [outText 'Step:' num2str(steps(1,2)) ' '];
end

if bonusText.CellType
    if bonusText.CellType == 1 || ~isempty(protocol.statName{8})
        outText = [outText protocol.statName{8} ' '];
    end
end

if bonusText.IntrinsicProp
    if bonusText.IntrinsicProp == 1 || ~isempty(protocol.statName{6})
        outText = [outText 'Intrinsic: ' protocol.statName{6} ' '];
    end
end

if bonusText.InternalName
    if bonusText.InternalName == 1 || ~isempty(protocol.statName{9})
        outText = [outText 'Internal: ' protocol.statName{9} ' '];
    end
end

if bonusText.SIUDescription
    % don't have this function
end

if bonusText.SIUTimes
    stims = findStims(protocol);
    for i = 1:numel(stims)
        if ~isempty(stims{i})
            outText = [outText 'TTL' sprintf('%0.0f', i - 1) ': ' num2str(stims{i}(1,:)) 'ms '];
        end
    end
end

if bonusText.SIUIntensity
    if bonusText.SIUIntensity == 1 || ~isempty(protocol.statValue(11))
        outText = [outText 'SIU=' sprintf('%0.0f', protocol.statValue(11)) ' '];
    end
end

if bonusText.PuffDrugNameLong
    if bonusText.PuffDrugNameLong == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{10} ' '];
    end
end

if bonusText.PuffDrugNameShort
    if bonusText.PuffDrugNameShort == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{10} ' '];
    end
end

if bonusText.PuffDescription
    if bonusText.PuffDescription == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{14} ' '];
    end
end

if bonusText.DrugLevel
    outText = [outText 'DL=' sprintf('%0.0f', protocol.drug)];
end

if bonusText.DrugNameLong
    if bonusText.DrugNameLong == 1 || ~isempty(protocol.statName{10})
        outText = [outText protocol.statName{10} ' '];
    end
end

if bonusText.DrugNameShort
    if bonusText.DrugNameShort == 1 || ~isempty(protocol.statName{10})
        outText = [outText protocol.statName{10} ' '];
    end
end

if bonusText.DrugTime
    outText = [outText 'DrugTime:' sec2time(protocol.drugTime) ' '];
end

if bonusText.SIUExtraText
    if bonusText.SIUExtraText == 1 || ~isempty(protocol.statName{11})
        outText = [outText 'SIU Disc: ' protocol.statName{11} ' '];
    end
end

if bonusText.ROIFileName
    if bonusText.ROIFileName == 1 || ~isempty(protocol.statName{12})
        outText = [outText 'ROI: ' protocol.statName{12} ' '];
    end
end

if bonusText.ImageFileName
    if bonusText.CellType == 1 || ~isempty(protocol.statName{13})
        outText = [outText 'Image: ' protocol.statName{13} ' '];
    end
end
