function forceOff
% turn off PMT, close shutter, release beam

if isappdata(0, 'rasterHandles')
    % for if persistent variables were cleared
    rasterHandles = getappdata(0, 'rasterHandles');
    ljHandle = rasterHandles{5};
    
    % close the shutter
    Error_Message(ljud_eGet(ljHandle, 40, 0, 1, 0)); 

    % unlock beam control
    Error_Message(ljud_eGet(ljHandle, 40, 1, 0, 0));      
    
    % turn off high voltage
    if calllib('ljackuw', 'DigitalIO', 0, 0, 255, 0, 45, 0, 1, 0) ~= 0
        error('Error in labjack digital controls.  Power off PMT immediately.')
    end    
end