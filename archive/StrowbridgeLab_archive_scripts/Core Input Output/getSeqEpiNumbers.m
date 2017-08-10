function SeqEpiStr = getSeqEpiNumbers (epiFileName)
  % returns a string like S4.E12 given a standard filename
  shortFileName = epiFileName(1:end-4); % truncates .DAT off
  numDots = 0;
  for i = numel(shortFileName):-1:1
      if strcmp(shortFileName(i), '.') == 1
         numDots = numDots + 1; 
      end
      if numDots == 2 
          break;
      end
  end
  SeqEpiStr = shortFileName(i + 1:end);
end