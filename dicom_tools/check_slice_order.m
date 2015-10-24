function slice_order=check_slice_order(dicom_path,varargin)
% For Siemens Scanner only
%check slice order and/or timing
flag = InspectVarargin(varargin,{'verbose'},{'on'});

%dicom_path = '/nfs/jong_exp/midbrain_pilots/dicoms/MP024_052913/3t_2013-05-29_10-35/008_RestingState_ep2d_TR3_ADVANCED_SHIM/0001.dcm';

dicom_slice_timing_identifier = 'Private_0019_1029';

dicom_header = dicominfo(dicom_path);
dicom_slice_timing = dicom_header.(dicom_slice_timing_identifier);

[~,I]=sort(dicom_slice_timing, 'ascend');
if mean(diff(I)) == 1 && range(diff(I)) == 0
    slice_order.series_name = 'ascending';
elseif mean(diff(I)) == -1 && range(diff(I)) == 0
    slice_order.series_name = 'descending';
else
    slice_order.series_name = 'interleaved';
    tmp = diff(I);
    if tmp(1)>0
        slice_order.series_name = [slice_order.series_name,'_ascending'];
    else
        slice_order.series_name = [slice_order.series_name,'_descending'];
    end
end

slice_order.slice_vector = I;
if strcmpi(flag,'on')
    disp(['slice order: ',slice_order.series_name]);
    disp([slice_order.slice_vector]);
end
end

    

