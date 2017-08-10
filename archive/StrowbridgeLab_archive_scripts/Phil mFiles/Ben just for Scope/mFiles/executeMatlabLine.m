function success = executeMatlabLine(inString)

try
    evalin('base', inString);
    success = 1;
catch
    msgbox(lasterr);
    success = 0;
end