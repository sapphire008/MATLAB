function retVector = SGfilterBen (InVector, PolyOrder, FrameSize)
retVector=sgolayfilt(InVector,PolyOrder,FrameSize);