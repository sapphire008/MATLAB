function [SIZE,JAGD]=IEX_mericSignalChar(X_vect,Y_vect,R_vect)
sample_rate=5;%sample rate of movement data [Hz]

%The following are Meric's signal characterization calculation
SIZE.X=norm(X_vect,2);
SIZE.Y=norm(Y_vect,2);
SIZE.X_Pos=norm(X_vect(X_vect>0));
SIZE.X_Neg=norm(X_vect(X_vect<0));
SIZE.Y_Pos=norm(Y_vect(Y_vect>0));
SIZE.Y_Neg=norm(Y_vect(Y_vect<0));
SIZE.R=norm(R_vect,2);
SIZE.Worst=max([SIZE.X SIZE.Y]);
SIZE.Sum=SIZE.X+SIZE.Y;
SIZE.Average=mean([SIZE.X SIZE.Y]);
JAGD.X=mean(abs(diff(X_vect)))*sample_rate;
JAGD.Y=mean(abs(diff(Y_vect)))*sample_rate;
JAGD.R=mean(abs(diff(R_vect)))*sample_rate;
JAGD.Worst=max([JAGD.X JAGD.Y]);
JAGD.Sum=JAGD.X+JAGD.Y;
JAGD.Average=mean([JAGD.X JAGD.Y]);   
end