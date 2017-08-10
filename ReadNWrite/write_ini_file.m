addmatlabpkg('generic');
addmatlabpkg('ephanalysis');

excelsheet = 'D:/Edward/Documents/Assignments/Case Western Reserve/StrowbridgeLab/Projects/Neocortex Persistence/analysis/Spike Frequency Adaptation - 02082017/Spike Frequency Adaptation.xlsx';
outfile = 'D:/Edward/Documents/Assignments/Case Western Reserve/StrowbridgeLab/Projects/Neocortex Persistence/ini/Terfenadine old.ini';

fid = fopen(outfile, 'w');
outerPath = 'D://Data/Traces/2016 | /Volumes/BenWork/Edward/2016';
sectionDivider = '#####################################################################';
returnKey = '\r\n';

%% Write header first
fprintf(fid, '[DEFAULT]'); fprintf(fid, returnKey);
fprintf(fid, 'selectedEpisodeKey = episodes'); fprintf(fid, returnKey);
fprintf(fid, 'outerPath = %s', outerPath); fprintf(fid, returnKey);
fprintf(fid, 'eventListPath = asdf | asdf'); fprintf(fid, returnKey);
fprintf(fid, 'channels = VoltA'); fprintf(fid, returnKey);
fprintf(fid, 'scopeCmd = setchan VoltA'); fprintf(fid, returnKey);
%% Aggregate the table: aggregate episodes
[~, ~, RAW] = xlsread(excelsheet, 'Terf_old');
% RAW = RAW(1:45, 1:10);
% RAW = [RAW(1,:); RAW(find(cell2mat(RAW(2:end,1))<6)+1,:)];
% RAW = [RAW(1,:); RAW(find(cell2mat(RAW(2:end,7))>0)+1,:)];
% RAW = [RAW(1,:); RAW(find(cell2mat(RAW(2:end,6))==-70)+1,:)];
% 
% RAW(2:end,:) = sortrows(RAW(2:end,:), [1, -4,6]);

%func_handle = @(x) strjoin(cellfun(@(y) y{1}{1}, regexp(x, 'S1.E(\d*)', 'tokens'), 'un',0),',');

func_handle1 = @(x) str2num(char(cellfun(@(y) y{1}{1}, regexp(x, 'S1.E(\d*)', 'tokens'), 'un',0)));
func_handle2 = @(x) printEpisodeNumber(func_handle1(x));
SUMMARY = aggregateR(RAW, {'Num', 'Cell', 'Drug'}, func_handle2, {'Episode'});
SUMMARY(2:end, :)=sortrows(SUMMARY(2:end,:), [1,-3]);

%% Write each section
for n = 2:size(SUMMARY,1)
    if ~strcmpi(SUMMARY{n,2}, SUMMARY{n-1,2}) % if new cell
        fprintf(fid,sectionDivider);  fprintf(fid, returnKey);
    end
    fprintf(fid, '[%s.%s]', SUMMARY{n,3}, SUMMARY{n,2}); fprintf(fid, returnKey);
    innerPath = strrep(fileparts(eph_cellpath(SUMMARY{n,2}, '1',[],true)),'\','/');
    fprintf(fid, 'innerPath = %s', innerPath); fprintf(fid, returnKey);
    fileRoot = [SUMMARY{n,2}, '.', 'S1.E'];
    fprintf(fid, 'fileRoot = %s', fileRoot); fprintf(fid, returnKey);
    fprintf(fid, 'episodes = %s', SUMMARY{n,4}); fprintf(fid, returnKey);
    fprintf(fid, 'comment = %s', ''); fprintf(fid, returnKey);
    fprintf(fid, returnKey);
end

fclose(fid);



