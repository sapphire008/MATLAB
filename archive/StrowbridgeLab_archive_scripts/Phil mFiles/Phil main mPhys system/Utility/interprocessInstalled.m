function progID = interprocessInstalled

% look to see if MB interprocess is installed and return its progID if so

progID = '';
list = actxcontrollist;

for i = 1:length(list)
    if strcmp(list{i, 1}, 'MBInterProcess.InterProc')
        progID = list{i, 2};
    end
end