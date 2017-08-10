function newKey = convertOldToNewKey(oldKey)
  letter = '';
  num = -1;
  switch oldKey(1:3)
      case 'Vol'
          newKey = 'Volt';
          num = str2double(oldKey(9));
      case 'Cur'
          newKey = 'Cur';
          num = str2double(oldKey(8));
      case 'Sti'
          newKey = 'Stim';
          letter = oldKey(14);
  end
  if num ~= -1 
     switch num
         case {0,1}
             letter = 'A';
         case {2,3}
             letter = 'B';
         case {4,5}
             letter = 'C';
         case {6,7}
             letter = 'D';  
     end
  end
  newKey = [newKey letter];
end