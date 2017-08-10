function sendMessage(message)

if ~isappdata(0, 'interProcess')
    startInterprocess;
end
interProcess = getappdata(0, 'interProcess');
interProcess.StringData = message;
interProcess.Send;    