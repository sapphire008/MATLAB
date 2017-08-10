function roiIndex = highlightROI(ROInum)
% highlight a ROI by number

ROI = getappdata(getappdata(0, 'imageDisplay'), 'ROI');
dataIndex = 0;
for roiIndex = 1:numel(ROI)
    if isempty(ROI(roiIndex).segments)
        dataIndex = dataIndex + 1;
        if dataIndex == ROInum
            set(ROI(roiIndex).handle, 'linewidth', 6, 'markersize', 18);
            set([ROI([1:roiIndex - 1 roiIndex + 1:numel(ROI)]).handle], 'linewidth', 2, 'markersize', 6);
        end
    else
        dataIndex = dataIndex + 1;     
        for segIndex = 1:numel(ROI(roiIndex).segments)
            if dataIndex == ROInum
                set(ROI(roiIndex).handle(segIndex), 'linewidth', 6, 'markersize', 18);
                set([ROI([1:roiIndex - 1 roiIndex + 1:numel(ROI)]).handle], 'linewidth', 2, 'markersize', 6);
                set(ROI(roiIndex).handle([1:segIndex - 1 segIndex + 1:numel(ROI(roiIndex).segments)]), 'linewidth', 2, 'markersize', 6);
            end               
            dataIndex = dataIndex + 1;
        end
        if dataIndex == ROInum
            set(ROI(roiIndex).handle(segIndex + 1), 'linewidth', 6, 'markersize', 18);
            set([ROI([1:roiIndex - 1 roiIndex + 1:numel(ROI)]).handle], 'linewidth', 2, 'markersize', 6);
            set(ROI(roiIndex).handle([1:segIndex segIndex + 2:numel(ROI(roiIndex).segments)]), 'linewidth', 2, 'markersize', 6);
        end           
    end
end
