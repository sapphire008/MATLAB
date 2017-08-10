function outData = countEvents(data, thresh)
outData = MTEO(data, 5, thresh);
outData = sum(outData >= 55000 & outData <= 80000);