function data_folder = eph_cellpath(cell_label, episode)
% infer full path of the cell given cell label (without file extension)
% and base directory of the path:
% e.g. Neocortex A.09Sep15.S1.E13 should yield
%  ./2015/09.September/Data 9 Sep 15/Neocortex A.09Sep15.S1.E13.dat

% Parse necessary information about date
%cell_label = 'Neocortex A.09Sep15';
if nargin<2, episode = '.%s'; end
if ~strcmpi(episode(1), '.'), episode = ['.', episode]; end
dinfo = regexp(cell_label, '([\w\s]+).(\d+)([a-z_A-Z]+)(\d+).S(\d+).E(\d+)','tokens');
if isempty(dinfo)
    dinfo = regexp(cell_label, '([\w\s]+).(\d+)([a-z_A-Z]+)(\d+)','tokens');
end
dinfo = dinfo{1};
% year folder
year_dir = ['20',dinfo{4}]; % be okay in this century
% month folder
month_dict = struct('Jan','01.January','Feb','02.February','Mar','03.March',...
    'Apr','04.April','May','05.May', 'Jun','06.June', 'Jul','07.July',...
    'Aug','08.August','Sep','09.September','Oct','10.Ocotobber',...
    'Nov','11.November','Dec','12.December');
month_dir = month_dict.(dinfo{3});
% data folder
data_folder = sprintf('Data %d %s %s', str2num(dinfo{2}), dinfo{3}, year_dir);
data_folder = fullfile(year_dir, month_dir, data_folder, [cell_label,episode,'.dat']);
end