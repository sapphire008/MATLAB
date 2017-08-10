%% separate data stream type
function MEA = separate_entity_type(MEA)
StreamType = cellfun(@(x) lower(x(1)),{MEA.EntityInfo.EntityLabel},'un',0);
[EntityList,~,INDEX] = unique(StreamType);
for n = 1:length(EntityList)
    switch EntityList{n}
        case 'e'
            F = 'Electrode';
        case 'a'
            F = 'Analog';
        case 'f'
            F = 'Filtered';
        case 'c'
            F = 'ChannelTool';
        case 'd'
            F = 'Digital';
        case 's'
            F = 'Spike';
        case 't'
            F = 'Trigger';
    end
    % Get the index
    MEA.(F).Index = find(INDEX == n);
    clear F;
end
end