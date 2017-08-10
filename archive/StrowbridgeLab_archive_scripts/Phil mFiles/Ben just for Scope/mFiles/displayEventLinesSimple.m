function retValue = displayEventLinesSimple(eventTimes,lineMin,lineMax)
  
       for eventIndex=1:numel(eventTimes)
           x1= (eventTimes(eventIndex) ) ;
          y1=lineMin;
          y2=lineMax;
           line([x1 x1], [y1 y2], 'color', 'b', 'linewidth', 2 );
       end
  retValue=0;
end