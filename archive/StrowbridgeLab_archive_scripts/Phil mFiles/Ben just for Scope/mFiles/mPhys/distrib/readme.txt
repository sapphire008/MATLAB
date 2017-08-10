MATLAB Builder NE (.NET Component)


1. Prerequisites for Deployment 

. Verify the MATLAB Compiler Runtime (MCR) is installed and ensure you    
  have installed version 7.16.   

. If the MCR is not installed, run MCRInstaller.exe, located in:

  <matlabroot>*\toolbox\compiler\deploy\win64\MCRInstaller.exe

For more information about the MCR and the MCR Installer, see 
“Working With the MCR” in the MATLAB Compiler User’s Guide.   
      
NOTE: You will need administrator rights to run MCRInstaller.

2. Files to Deploy and Package

-mPhys.dll
   -contains the generated component using MWArray API. 
-mPhysNative.dll
   -contains the generated component using native API.
-This readme file

. If the target machine does not have version 7.16 of 
  the MCR installed, include MCRInstaller.exe.



Auto-generated Documentation Templates:

MWArray.xml - This file contains the code comments for the MWArray data conversion 
              classes and their methods. This file can be found in either the component 
              distrib directory or in
              <mcr_root>*\toolbox\dotnetbuilder\bin\win64\v2.0

mPhys_overview.html - HTML overview documentation file for the generated component. It 
                      contains the requirements for accessing the component and for 
                      generating arguments using the MWArray class hierarchy.

mPhys.xml - This file contains the code comments for the mPhys component classes and 
                      methods. Using a third party documentation tool, this file can be 
                      combined with either or both of the previous files to generate 
                      online documentation for the mPhys component.

                 


3. Resources

To learn more about:               See:
================================================================================================
The MWArray classes                MATLAB product help or <mcr_root>*\
                                   help\toolbox\dotnetbuilder\MWArrayAPI\MWArrayAPI.chm
Examples of .NET Web Applications  MATLAB Application Deployment 
                                   Web Example Guide


4. Definitions

For information on deployment terminology, go to 
http://www.mathworks.com/help. Select your product and see 
the Glossary in the User’s Guide.



* NOTE: <matlabroot> is the directory where MATLAB is installed on the target machine.
        <mcr_root> is the directory where MCR is installed on the target machine.
