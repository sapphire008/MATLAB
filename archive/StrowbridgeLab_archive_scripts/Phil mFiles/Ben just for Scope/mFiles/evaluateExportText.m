function outText = evaluateExportText
% short and long concentrations are the same
protocol = evalin('base', 'zData.protocol');
if numel(protocol) > 1
    outText = get(gcf, 'name');
    return
end
outText = '';

exportText = getappdata(0, 'exportText');
if ~isstruct(exportText)
    return
end
ampNum = 1;

if exportText.ShortFileName
    outText = [outText protocol.fileName(find(protocol.fileName == filesep, 1, 'last') + 1:end) '  '];
end

if exportText.FullFileName
    outText = [outText protocol.fileName '  '];
end

if exportText.BaselineVm
    outText = [outText  'Initial: ' sprintf('%0.1f', protocol.startingValues(whichChannel(protocol, ampNum, 'V'))) ' mV '];
end

if exportText.BaselineIm
    outText = [outText    sprintf('%0.0f', protocol.startingValues(whichChannel(protocol, ampNum, 'I'))) ' pA  ' ];
end

if exportText.WCTime
    outText = [outText 'WC Time: ' sec2time(protocol.cellTime) ' min  '];
end

if exportText.StepAmplitude
    steps = findSteps(protocol, ampNum);
    outText = [outText 'Step ' num2str(steps(1,2)) ' '];
end

if exportText.CellType
    if exportText.CellType == 1 || ~isempty(protocol.statName{8})
        outText = [outText protocol.statName{8} ' '];
    end
end

if exportText.IntrinsicProp
    if exportText.IntrinsicProp == 1 || ~isempty(protocol.statName{6})
        outText = [outText 'Intrinsic: ' protocol.statName{6} ' '];
    end
end

if exportText.InternalName
    if exportText.InternalName == 1 || ~isempty(protocol.statName{9})
        outText = [outText 'Internal: ' protocol.statName{9} ' '];
    end
end

if exportText.SIUDescription
    % don't have this function
end

if exportText.SIUTimes
    stims = findStims(protocol);
    for i = 1:numel(stims)
        if ~isempty(stims{i})
            outText = [outText 'TTL' sprintf('%0.0f', i - 1) ': ' num2str(stims{i}(1,:)) 'ms '];
        end
    end
end

if exportText.SIUIntensity
    if exportText.SIUIntensity == 1 || ~isempty(protocol.statValue(11))
        outText = [outText 'SIU=' sprintf('%0.0f', protocol.statValue(11)) ' '];
    end
end

if exportText.PuffDrugNameLong
    if exportText.PuffDrugNameLong == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{10} ' '];
    end
end

if exportText.PuffDrugNameShort
    if exportText.PuffDrugNameShort == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{10} ' '];
    end
end

if exportText.PuffDescription
    if exportText.PuffDescription == 1 || ~isempty(protocol.statName{14})
        outText = [outText 'Puff:' protocol.statName{14} ' '];
    end
end

if exportText.DrugLevel
    outText = [outText 'DL ' sprintf('%0.0f', protocol.drug) '  '];
end

if exportText.DrugNameLong
    if exportText.DrugNameLong == 1 || ~isempty(protocol.statName{10})
        outText = [outText protocol.statName{10} ' '];
    end
end

if exportText.DrugNameShort
    if exportText.DrugNameShort == 1 || ~isempty(protocol.statName{10})
        outText = [outText protocol.statName{10} ' '];
    end
end

if exportText.DrugTime
    outText = [outText 'DrugTime ' sec2time(protocol.drugTime) ' '];
end

if exportText.SIUExtraText
    if exportText.SIUExtraText == 1 || ~isempty(protocol.statName{11})
        outText = [outText 'SIU Disc: ' protocol.statName{11} ' '];
    end
end

if exportText.ROIFileName
    if exportText.ROIFileName == 1 || ~isempty(protocol.statName{12})
        outText = [outText 'ROI: ' protocol.statName{12} ' '];
    end
end

if exportText.ImageFileName
    if exportText.CellType == 1 || ~isempty(protocol.statName{13})
        outText = [outText 'Image: ' protocol.statName{13} ' '];
    end
end

%  outText='H :\ Data Test\May 16 2008\Hilar A.16May08.S2.E91.dat Initial -57.2 mV 12 pA  WC Time  0:00:48.3 min';
