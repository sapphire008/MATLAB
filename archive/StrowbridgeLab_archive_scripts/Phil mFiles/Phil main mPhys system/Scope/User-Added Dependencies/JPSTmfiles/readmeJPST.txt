To use JPST.m

This program  is in development, but useable.  It shouldn't crash, but I would keep verbose mode (Display->verbose mode) checked.  If something doesn't look right, check the command window to see what the program has done.

0.  Your data file needs to be in 'gdf' format.  A gdf file has the extension '.gdf', and is an ascii file of the following structure:
Column 1:  an event, coded as an integer 1 to some really big number
Column 2:  a time corresponding to the event on the same row, coded as an integer 1 to some really big number

The events are spikes, stimuli, and any other thing that you might want to align on, or examine.  The times are in 'ticks', you will have to enter how many ticks there are per ms when you run the JPST script.  eg, sampling at 25000Hz = 25 ticks per ms.

Part of a gdf file is shown below.  Note that the times (second column) have to be in ascending order.  Here all the events are numbers from 20001 to 20007. You will need to enter which of these IDs are spikes, and which are codes to align on when you run the JPST script.  Gdf files can easily have hundreds of thousands events.

20002 357284
20001 357294
20007 357307
20005 357308
20007 357341
20003 357346
20006 357355
20007 357372
20004 357386
20001 357418
20001 357439
20005 357458
20007 357464
20003 357469
20007 357493
20007 357540



1. Put all the *.m and *.mat files in a directory of your choosing.

2. Run matlab, and cd to that directory.

3. Type 'JPST' at the matlab prompt.

4. A window will come up asking you to load a *.gdf file. Find a file and load it.

5. An options dialog will probably appear, asking you to enter some information.  If it does not appear, then after the file is loaded, go to Options -> options to run the dialog.

6. Enter the number ranges in which spikes will appear, and in which events which you would like to align on appear.  This is for convince only, when the file is loaded only valid choices will be offered.  You can always put both ranges to 1- 65000 or so, to get all choices.  However, accidentally aligning on a cell ID can take a lot of time!

7. Enter the number of ticks per millisecond, partial ticks are okay (eg, 25.7)

8. Enter the maximum ms before any align and that after any align you want to use.  This is used to build the sliders for time selection.

9. Enter the bin widths you want to use, this is used to make a pull down menu.

10. You can run this dialog at any time (Options -> options) to change these values.  Save and these values will be saved on disk, and used until you change them.

11. Play with the program.  You will probably want to run Display-> normalized for most of your analyses, this is the calcuation described in the Aertsen et al paper of 1989.

12. Binomial errors are only important for the significance calculation, and it is not running correctly so don't use it except to play.  Other calculations are correct.

13. It shouldn't crash!  Unless you run out of memory....

Let me know about all the problems (it is not running optimally yet), or questions about what is going on:

jeff@mulab.physiol.upenn.edu

You can also run this program from a script, or get values from the calculation.  It you want to know how, just ask.

  regards, -jeff

