% Call the ljud_eGet function from the MATLAB command window or any other
% mfile. To call the function use the following notation:
%
% [Error Value] = ljud_eGet(Parameters)
%
% Error should be returned as a zero, and Value will be the data requested.
% See Section 3.3 of the LabJackUD_Driver_For_Windows.pdf for more
% information on the eGet function and the required paramters.

function [ljError, ljValue] = ljud_eGet(ljHandle, IOType, Channel, ljValue, x1)

    ljError = 1;
    i = 1;
    while ljError ~= 0 && i <= 10
        [ljError, ljValue] = calllib('labjackud','eGet',ljHandle,IOType,Channel,ljValue,x1);
        i = i + 1;
        pause(0.01);
    end
    if ljError ~= 0
        error('Error communicating with shutter/pockel cell controller');
    end