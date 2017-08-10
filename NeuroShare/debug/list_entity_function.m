%% list functions need to be used for each corresponding entity type
function [entity_name,info_fhandle, data_fhandle] = list_entity_function(entity_type)
for n = 1:length(entity_type)
    switch entity_type
        case 1
            info_fhandle = @ns_GetEventInfo;
            data_fhandle = @ns_GetEventData;
            entity_name = 'event';
        case 2
            info_fhandle = @ns_GetAnalogInfo;
            data_fhandle = @ns_GetAnalogData;
            entity_name = 'channel';
        case 3
            info_fhandle = @ns_GetSegmentInfo;
            data_fhandle = @ns_GetSegmentData;
            entity_name = 'spike';
    end
end
end