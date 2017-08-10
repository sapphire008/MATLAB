function exportFigure(src, eventInfo, figHandle, toPaper)
% function for converting a figHandle to paper, clipboard memory, or file
% toPaper = 1 prints
% toPaper = 0 copys to clipboard as meta file
% toPaper = 2 saves an image of the figHandle
% toPaper = 3 saves a nonimage output file type

    if nargin == 0
        figHandle = gcf;
    end
    if nargin < 2
        toPaper = 1;
    end
    
    mouseCallbacks = {get(figHandle, 'WindowButtonMotionFcn') get(figHandle, 'WindowButtonDownFcn') get(figHandle, 'WindowButtonUpFcn') get(figHandle, 'resizefcn')};    
    axisHandles = findobj(get(figHandle, 'children'), 'type', 'axes');
%     
%     % add scale bar
%     for i = 1:numel(axisHandles)
%         newAxis(i) = copyobj(axisHandles(i), figHandle);
%         set(axisHandles(i), 'visible', 'off');
%         prepForPrint(newAxis(i));
%     end
    
    % meta files print at screen resolution so for high resolution data
    % export as a plotter file and then import with Corel
    switch toPaper
        case 0
            print('-dmeta', '-r600', figHandle);
        case 1
            print('-v', '-noui', figHandle);
        case 2
            F = getframe(axisHandles(1));
            newHandle = figure('visible', 'off');
            saveImageAs(imshow(F.cdata));
            delete(newHandle);
        case 3
            extData = {'*.eps', 'Encapsulated Postscript (EPS)'; '*.ill', 'Adobe Illustrator (ILL)'; '*.pdf', 'Portable Document Format (PDF)'};
            [fileName,pathName,filterIndex] = uiputfile(extData, 'Select Location to Save File');
            switch filterIndex
                case 1
                    print('-depsc2', '-r4800', '-noui', [pathName fileName], figHandle)
                case 2
                    print('-dill', '-noui', [pathName fileName], figHandle)
                case 3
                    print('-dpdf', '-noui', [pathName fileName], figHandle)
            end
    end

    set(figHandle, 'WindowButtonMotionFcn', mouseCallbacks{1}, 'WindowButtonDownFcn', mouseCallbacks{2}, 'WindowButtonUpFcn', mouseCallbacks{3}, 'resizefcn', mouseCallbacks{4});    
%     delete(newAxis);
%     set(axisHandles, 'visible', 'on');