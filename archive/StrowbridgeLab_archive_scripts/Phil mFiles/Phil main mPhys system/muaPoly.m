function muaPoly(data, protocol)

clipText = '';
for i = 1:numel(protocol)
    events = detectExtracellular(data, protocol(i).timePerPoint / 1000) * protocol(i).timePerPoint / 1000;
    clipText = [clipText protocol(i).fileName(find(protocol(i).fileName == filesep, 1, 'last') + 1:end - 4) char(9) num2str(sum(events < 10000)) char(9) num2str(sum(events >= 11000 & events <= 14000)) char(13)];
end
clipboard('copy', clipText);