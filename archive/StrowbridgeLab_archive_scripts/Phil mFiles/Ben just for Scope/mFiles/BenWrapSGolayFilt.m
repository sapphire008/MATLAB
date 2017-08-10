function retVector = BenWrapSGolayFilt (InVector, PolyOrder, FrameSize)
retVector=sgolayfilt(InVector,PolyOrder,FrameSize);