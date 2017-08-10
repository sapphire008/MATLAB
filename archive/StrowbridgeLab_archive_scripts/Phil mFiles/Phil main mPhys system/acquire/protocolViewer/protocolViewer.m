function figHandle = protocolViewer(appdataName)

if nargin < 1
	appdataName = 'protocolViewer';
end

% opens a gui that allows viewing of a protocol structure

if ~isappdata(0, appdataName)
    % load main frame
        figHandle = hgload('main.fig');
        set(figHandle, 'color', get(0, 'defaultUicontrolBackgroundColor'));
        
    % make sure all preferences are present
        if ~ispref('experiment', 'internals')
            setpref('experiment', 'internals', {'-None-', 'Cs-methanesulfonate (19)', 'K-methanesulfonate (27)'});
            setpref('experiment', 'baths', {'-None-', '0 Mg', '3 mM K', '5 mM K'});
            setpref('experiment', 'drugs', {'-None-', 'APV (25 uM)', 'NBQX (5 uM)', 'TTX (1 uM)'});
			setpref('experiment', 'cellTypes', {'CA1', 'CA3', 'DGCL', 'Hilar', 'IML'});
			setpref('experiment', 'ttlTypes', {'SIU, tungsten, PP', 'Puff (5 mM Glu)'});
            currentAmps;
        end
		
	% set its location
		if ~ispref('locations', appdataName)
			setpref('locations', appdataName, [2130 670 704 416]);
		end	
		set(figHandle, 'position', getpref('locations', appdataName), 'tag', appdataName);
		
    % load tabs
        props.visible = 'off';
        tempHandle = hgload('channelPanel.fig', props);
        copyobj(get(tempHandle, 'children'), figHandle);
        delete(tempHandle);    
        tempHandle = hgload('imagingPanel.fig', props);
        warning('off', 'MATLAB:childAddedCbk:CallbackWillBeOverwritten');
        copyobj(get(tempHandle, 'children'), figHandle);
        delete(tempHandle);     
        createTTL(figHandle);
        tempHandle = hgload('ampContainer.fig', props);
        copyobj(get(tempHandle, 'children'), figHandle);
        delete(tempHandle);

        handles = guihandles(figHandle);
        
    % add the callback for adding amps
        tempMenu = uicontextmenu('parent', figHandle);
        uimenu(tempMenu, 'label', 'Add', 'callback', 'addAmp');
        set(handles.pnlAmps, 'uicontextmenu', tempMenu);     

    % generate handles structure
        info.numAmps = 0;    
        info.tabButtons = [handles.tabAmps handles.tabTTLs handles.tabImaging handles.tabChannels];
        info.lineHiders = [handles.hideAmps handles.hideTTLs handles.hideImaging handles.hideChannels];
        set(info.lineHiders, 'backgroundColor', get(0, 'defaultUicontrolBackgroundColor'));
        info.panels = [handles.pnlAmps handles.pnlTTLs handles.pnlImaging handles.pnlChannels];
        set(info.tabButtons, 'callback', 'tabChange');   
        set(figHandle, 'closeRequestFcn', @closeMe);   
		setappdata(figHandle, 'tabData', info);
		
    % tell posterity that this exists
        setappdata(0, appdataName, figHandle);
		set(figHandle, 'userData', guihandles(figHandle));
		
	% load up the channelPanel
		changeAdBoard(figHandle);		
        
    % show the figure
        set(figHandle, 'visible', 'on');
else
    figHandle = figure(getappdata(0, appdataName));
end    

onScreen(figHandle);

	function closeMe(varargin)
		set(figHandle, 'units', 'pixel');
		setpref('locations', appdataName, get(figHandle, 'position'));
		if ~strcmp(appdataName, 'runningProtocol')
			rmappdata(0, appdataName);
			delete(figHandle);
		else
			set(figHandle, 'visible', 'off');			
		end
	end
end