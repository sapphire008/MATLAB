function makeEpisodes(eps1, eps2, printwhat)
addmatlabpkg('generic');
addmatlabpkg('ephanalysis');

if nargin<3
    CellName = 'Neocortex B.23Aug16';
    eps1 = [55:78];
    eps2 = 208:231;
    
    printwhat={'Pair'};
end

SHEET1 = makeSheet(CellName, eps1, {'Episodes1', 'Stim'});
SHEET2 = makeSheet(CellName, eps2, {'Episodes2', 'Stim'});
% Summarize the sheet
joinmystr = @(x) ['(', strjoin(x, '+'), ')/', num2str(length(x))];
SUMMARY1 = aggregateR(SHEET1, {'Stim'}, joinmystr, {'Episodes1'});
SUMMARY1 = SUMMARY1(1:9,:);
SUMMARY2 = aggregateR(SHEET2, {'Stim'}, joinmystr, {'Episodes2'});
% Turn into table
SUMMARY1_t = cell2table(SUMMARY1(2:end,:), 'VariableNames', SUMMARY1(1,:));
SUMMARY2_t = cell2table(SUMMARY2(2:end,:), 'VariableNames', SUMMARY2(1,:));
% Join the table
C =  join(SUMMARY1_t, SUMMARY2_t);
% Difference
C.Diff = cell(size(C, 1),1);
for n = 1:length(C.Diff)
    C.Diff{n} = [C.Episodes2{n}, '-', C.Episodes1{n}];
end
% printing
if ismember('Individual', printwhat)
    printIndividual(C.Stim, C.Episodes1);
    printIndividual(C.Stim, C.Episodes2);
    printIndividual(C.Stim, C.Diff);
end
if ismember('Family', printwhat)
    printFamily(C.Episodes1);
    printFamily(C.Episodes2);
    printFamily(C.Diff);
end
if ismember('Pair', printwhat)
    printPair(C.Stim, C.Episodes1, C.Episodes2);
end
end
%%
function SHEET = makeSheet(CellName, eps, head)
SHEET = head;
for n = eps
    ep = sprintf('S1.E%d', n);
    zData = eph_load(sprintf([CellName,'.S1.E%d'], n));
    stim = zData.protocol.dacData{1}(21);
    SHEET{end+1, 1} = ep;
    SHEET{end,2} = stim;
end
end

%% individual
function printIndividual(Stim, Episodes)
for n = 1:length(Stim)
    fprintf('%d', Stim(n));
    fprintf(': ');
    fprintf(Episodes{n});
    fprintf('\n');
end
end

%% family
function printFamily(Episodes)
fprintf('{');
fprintf(strjoin(Episodes,';'));
fprintf('}\n');
end

%% pair
function printPair(Stim, Episodes1, Episodes2)
for n = 1:length(Stim)
    fprintf('%d', Stim(n));
    fprintf(': ');
    fprintf('{');
    fprintf(Episodes1{n});
    fprintf(';');
    fprintf(Episodes2{n});
    fprintf('}');
    fprintf('\n');
end
end