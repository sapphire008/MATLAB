function [subject] = readcsv(str)
% [subject] = readstroopcsv(str)
% str = type string - the name of the subject edat file to be read
% subject = type cell array - containing the data from the file
%str = 'epc46_stroop.csv'
fid = fopen(str, 'r');
if((fid == -1)),
    disp('File not opened')
else
    headers = textscan(fid,'%s %s %s %s %s %s %s %s %s %s %s %s',1,'delimiter', ',');
    data =    textscan(fid,'%d %d %d %d %d %d %d %d %d %d %d %s','delimiter', ',');
    fclose(fid);
    % create a cell object = each entry contains header and data
    for n = 1:length(headers),
        file = ['subject{n}.col = data{n};'];
        eval(file);
        subject{n}.header = headers{n};
    end
end

