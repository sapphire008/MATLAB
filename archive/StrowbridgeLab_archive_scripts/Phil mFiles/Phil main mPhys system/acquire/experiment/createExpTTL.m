function checkHandles = createExpTTL(numTTL, pnlHandle)
checkHandles = [];

if nargin < 2
    if isappdata(0, 'experiment')
        handles = get(getappdata(0, 'experiment'), 'userData');
        pnlHandle = handles.ttlHolder;
    else
        return
    end
end

% remove old check boxes
delete(findobj(pnlHandle, 'tag', 'ttlEnable'));
set(findobj(get(pnlHandle, 'parent'), 'tag', 'ttlScroll'), 'visible', 'off');

% creat TTL check boxes
switch numTTL
    case 4
        for i = 3:-1:0 % front panel
            checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', ['TTL ' num2str(i)], 'tag', 'ttlEnable', 'position', [0.4 + i * 10.6 0.1 9.4 1.1], 'toolTipString', ['TTL ' num2str(i)]);
        end
    case 8
        for i = 7:-1:0 % rear panel half
            if (i + 1)/4 == round((i + 1)/4)
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', num2str(i), 'tag', 'ttlEnable', 'position', [0.4 + i * 5.3 0.1 5.5 1.1], 'toolTipString', ['TTL ' num2str(i)], 'backgroundColor', [0 0 1]);
            else
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', num2str(i), 'tag', 'ttlEnable', 'position', [0.4 + i * 5.3 0.1 5.5 1.1], 'toolTipString', ['TTL ' num2str(i)]);
            end
        end
    case 16
        for i = 15:-1:0 % rear panel full
            if (i + 1)/4 == round((i + 1)/4)
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', '', 'tag', 'ttlEnable', 'position', [0.4 + i * 2.6 0.1 2.4 1.1], 'toolTipString', ['TTL ' num2str(i)], 'backgroundColor', [0 0 1]);
            else                    
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', '', 'tag', 'ttlEnable', 'position', [0.4 + i * 2.6 0.1 2.4 1.1], 'toolTipString', ['TTL ' num2str(i)]);
            end
        end
    otherwise
        % put these on a scrolling panel of sorts
        set(findobj(get(pnlHandle, 'parent'), 'tag', 'ttlScroll'), 'visible', 'on', 'callback', @scrollTTLs, 'value', 0, 'min', 0, 'max', numTTL - 17, 'sliderStep', [1 17] ./ (numTTL - 17));         
        for i = numTTL-1:-1:0
            if (i + 1)/4 == round((i + 1)/4)
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', '', 'tag', 'ttlEnable', 'position', [0.4 + i * 2.6 0.1 2.4 1.1], 'toolTipString', ['TTL ' num2str(i)], 'backgroundColor', [0 0 1]);
            else                    
                checkHandles(i + 1) = uicontrol('units', 'char', 'callback', 'saveExperiment;', 'style', 'check', 'parent', pnlHandle, 'string', '', 'tag', 'ttlEnable', 'position', [0.4 + i * 2.6 0.1 2.4 1.1], 'toolTipString', ['TTL ' num2str(i)]);
            end
        end
        set(checkHandles(17:end), 'visible', 'off');
end
try
    saveExperiment;
catch
    
end

    function scrollTTLs(varargin)
        kids = findobj(pnlHandle, 'tag', 'ttlEnable');
        sliderOffset = numTTL - 17 - get(varargin{1}, 'value');
        set(pnlHandle, 'position', [1.2 - (numTTL - 17 - sliderOffset) * 2.6 1.95 2.4 1.1]);
        set(kids(round([1:(numTTL  - 17 - sliderOffset) (numTTL - sliderOffset) + 1:end])), 'visible', 'off')
        set(kids(round((numTTL  - 17 - sliderOffset) + 1:(numTTL - sliderOffset))), 'visible', 'on');      
    end    
end