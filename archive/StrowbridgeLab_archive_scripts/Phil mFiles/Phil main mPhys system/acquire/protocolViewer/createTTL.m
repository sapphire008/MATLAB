function createTTL(figHandle, numTTL)

if nargin < 2
    if isappdata(0, 'experiment');
        numTTL = numel(get(findobj(getappdata(0, 'experiment'), 'tag', 'ttlHolder'), 'children')) - 1;
    else
        numTTL = 3; % front panel
%        numTTL = 7; % rear panel
%        numTTL = 15; % rear panel   
    end
end

% delete the old stuff
delete(findobj(figHandle, 'tag', 'pnlTTLs'));

props.visible = 'off';
tempHandle = hgload('ttlContainer.fig', props);
containerHandle = copyobj(get(tempHandle, 'children'), figHandle);
ttlHandle = hgload('ttlPanel.fig', props);     
for i = numTTL:-1:0 
    kids = copyobj(get(ttlHandle, 'children'), containerHandle);
    set(kids(2), 'position', [0.4 + 34.6 * i .231 34 28.692], 'userData', [0.4 + 34.6 * i .231 34 28.692]);
    set(kids(1), 'position', [2.6 + 34.6 * i 28.215 18.2 1.154], 'userData', [2.6 + 34.6 * i 28.215 18.2 1.154], 'string', ['TTL Channel ' num2str(i)]);
    kidKids = get(kids(2), 'children');
    set(kidKids(1), 'string', [getpref('experiment', 'ttlTypes') 'Other']);
end
if numTTL > 3
    set(findobj(containerHandle,'style', 'slider'), 'visible', 'on', 'callback', @scrollTTL, 'value', 0, 'min', 0, 'max', 34.6 * (numTTL - 3), 'sliderStep', [1 4] ./ (numTTL - 3)); 
else
    set(findobj(containerHandle,'style', 'slider'), 'visible', 'off'); 
end

delete(tempHandle);
delete(ttlHandle);  

% update the tabs button callbacks
tabInfo = getappdata(figHandle, 'tabData');
tabInfo.panels(2) = containerHandle;
setappdata(figHandle, 'tabData', tabInfo);

        
    function scrollTTL(varargin)
        kids = get(containerHandle, 'children');
        sliderOffset = get(varargin{1}, 'value');
        for ttlIndex = kids(1:end - 1)'
            set(ttlIndex, 'position', get(ttlIndex, 'userData') - [sliderOffset 0 0 0]);
        end        
    end
end