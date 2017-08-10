
% device types
LJ_dtUE9 = 9;
LJ_dtU3 = 3;
 
% connection types:
LJ_ctUSB = 1; % UE9 + U3
LJ_ctETHERNET = 2; % UE9 only

LJ_ctUSB_RAW = 101; % UE9 + U3
LJ_ctETHERNET_RAW = 102; % UE9 only

% io types:
LJ_ioGET_AIN = 10; % UE9 + U3.  This is single ended version.  
LJ_ioGET_AIN_DIFF = 15; % U3 only.  Put second channel in x1.  If 32 is passed as x1, Vref will be added to the result. 

LJ_ioPUT_AIN_RANGE = 2000; % UE9
LJ_ioGET_AIN_RANGE = 2001; % UE9
% sets or reads the analog or digital mode of the FIO and EIO pins.  FIO is Channel 0-7, EIO 8-15
LJ_ioPUT_ANALOG_ENABLE_BIT = 2013; % U3 
LJ_ioGET_ANALOG_ENABLE_BIT = 2014; % U3 


LJ_ioPUT_ANALOG_ENABLE_PORT = 2015; % U3 
LJ_ioGET_ANALOG_ENABLE_PORT = 2016; % U3

LJ_ioPUT_DAC = 20; % UE9 + U3
LJ_ioPUT_DAC_ENABLE = 2002; % UE9 + U3 (U3 on Channel 1 only)
LJ_ioGET_DAC_ENABLE = 2003; % UE9 + U3 (U3 on Channel 1 only)

LJ_ioGET_DIGITAL_BIT = 30; % UE9 + U3  % changes direction of bit to input as well
LJ_ioGET_DIGITAL_BIT_DIR = 31; % U3
LJ_ioGET_DIGITAL_BIT_STATE = 32; % does not change direction of bit, allowing readback of output

% channel is starting bit #, x1 is number of bits to read 
LJ_ioGET_DIGITAL_PORT = 35; % UE9 + U3  % changes direction of bits to input as well
LJ_ioGET_DIGITAL_PORT_DIR = 36; % U3
LJ_ioGET_DIGITAL_PORT_STATE = 37; % U3 does not change direction of bits, allowing readback of output

% digital put commands will set the specified digital line(s) to output
LJ_ioPUT_DIGITAL_BIT = 40; % UE9 + U3
% channel is starting bit #, value is output value, x1 is bits to write
LJ_ioPUT_DIGITAL_PORT = 45; % UE9 + U3

% Used to create a pause in a feedback packet for creating pulses.  Channel value is empty
% number of microseconds to pause is passed in as value.  Accuracy of 100 microseconds
% with .5s limit. 
LJ_ioPUT_WAIT = 70; % U3

% counter.  Input only.
LJ_ioGET_COUNTER = 50; % UE9 + U3

LJ_ioPUT_COUNTER_ENABLE = 2008; % UE9 + U3
LJ_ioGET_COUNTER_ENABLE = 2009; % UE9 + U3

% this will cause the designated counter to reset.  If you want to reset the counter with
% every read, you have to use this command every time.
LJ_ioPUT_COUNTER_RESET = 2012;  % UE9 + U3 

% on UE9: timer only used for input. Output Timers don't use these.  Only Channel used.
% on U3: Channel used (0 or 1).  
LJ_ioGET_TIMER = 60; % UE9 + U3

LJ_ioPUT_TIMER_VALUE = 2006; % UE9 + U3.  Value gets new value
LJ_ioPUT_TIMER_MODE = 2004; % UE9 + U3.  On both Value gets new mode.  
LJ_ioGET_TIMER_MODE = 2005; % UE9

% IOTypes for use with SHT sensor.  For LJ_ioSHT_GET_READING, a channel of LJ_chSHT_TEMP (0) will 
% read temperature, and LJ_chSHT_RH (1) will read humidity.  
% The LJ_ioSHT_DATA_CHANNEL and LJ_ioSHT_SCK_CHANNEL iotypes use the passed channel 
% to set the appropriate channel for the data and SCK lines for the SHT sensor. 
% Default digital channels are FIO0 for the data channel and FIO1 for the clock channel. 
LJ_ioSHT_GET_READING = 500; % UE9 + U3.
LJ_ioSHT_DATA_CHANNEL = 501; % UE9 + U3. Default is FIO0
LJ_ioSHT_CLOCK_CHANNEL = 502; % UE9 + U3. Default is FIO1

 
LJ_ioPIN_CONFIGURATION_RESET = 2017; % U3


LJ_ioRAW_OUT = 100; % UE9 + U3
LJ_ioRAW_IN = 101; % UE9 + U3

LJ_ioSET_DEFAULTS = 103; % U3


LJ_ioADD_STREAM_CHANNEL = 200;
LJ_ioCLEAR_STREAM_CHANNELS = 201;
LJ_ioSTART_STREAM = 202;
LJ_ioSTOP_STREAM = 203;

LJ_ioGET_STREAM_DATA = 204;



LJ_ioSET_STREAM_CALLBACK = 205;

% U3 only:

% Channel = 0 buzz for a count, Channel = 1 buzz continuous
% Value is the Period
% X1 is the toggle count when channel = 0
LJ_ioBUZZER = 300; % U3 


LJ_ioPUT_CAL_CONSTANTS = 400;
LJ_ioGET_CAL_CONSTANTS = 401;
LJ_ioPUT_USER_MEM = 402;
LJ_ioGET_USER_MEM = 403;

% config iotypes:
LJ_ioPUT_CONFIG = 1000; % UE9 + U3
LJ_ioGET_CONFIG = 1001; % UE9 + U3

% channel numbers used for CONFIG types:
% UE9 + U3
LJ_chLOCALID = 0; % UE9 + U3
LJ_chHARDWARE_VERSION = 10; % UE9 + U3
LJ_chSERIAL_NUMBER = 12; % UE9 + U3
LJ_chFIRMWARE_VERSION = 11; % U3 
LJ_chBOOTLOADER_VERSION = 15; % U3

% UE9 specific:
LJ_chCOMM_POWER_LEVEL = 1; %UE9
LJ_chIP_ADDRESS = 2; %UE9
LJ_chGATEWAY = 3; %UE9
LJ_chSUBNET = 4; %UE9
LJ_chPORTA = 5; %UE9
LJ_chPORTB = 6; %UE9
LJ_chDHCP = 7; %UE9
LJ_chPRODUCTID = 8; %UE9
LJ_chMACADDRESS = 9; %UE9
LJ_chCOMM_FIRMWARE_VERSION = 11;  
LJ_chCONTROL_POWER_LEVEL = 13; %UE9
LJ_chCONTROL_FIRMWARE_VERSION = 14; %UE9
LJ_chCONTROL_BOOTLOADER_VERSION = 15; %UE9 
LJ_chCONTROL_RESET_SOURCE = 16; %UE9
LJ_chUE9_PRO = 19; % UE9
% U3 only:
% sets the state of the LED 
LJ_chLED_STATE = 17; % U3   value = LED state
LJ_chSDA_SCL = 18; % U3   enable / disable SDA/SCL as digital I/O


% timer/counter related
LJ_chNUMBER_TIMERS_ENABLED = 1000; % UE9 + U3
LJ_chTIMER_CLOCK_BASE = 1001; % UE9 + U3
LJ_chTIMER_CLOCK_DIVISOR = 1002; % UE9 + U3
LJ_chTIMER_COUNTER_PIN_OFFSET = 1003; % U3

% AIn related
LJ_chAIN_RESOLUTION = 2000; % ue9 + u3
LJ_chAIN_SETTLING_TIME = 2001; % ue9 + u3
LJ_chAIN_BINARY = 2002; % ue9 + u3

% DAC related
LJ_chDAC_BINARY = 3000; % ue9 + u3

% SHT related
LJ_chSHT_TEMP = 5000;
LJ_chSHT_RH = 5001;

% stream related.  Note, Putting to any of these values will stop any running streams.
LJ_chSTREAM_SCAN_FREQUENCY = 4000;
LJ_chSTREAM_BUFFER_SIZE = 4001;
LJ_chSTREAM_CLOCK_OUTPUT = 4002;
LJ_chSTREAM_EXTERNAL_TRIGGER = 4003;
LJ_chSTREAM_WAIT_MODE = 4004;
% readonly stream related
LJ_chSTREAM_BACKLOG_COMM = 4105;
LJ_chSTREAM_BACKLOG_CONTROL = 4106;

% special channel #'s
LJ_chALL_CHANNELS = -1;
LJ_INVALID_CONSTANT = -999;


% other constants:
% ranges (not all are supported by all devices):
LJ_rgBIP20V = 1;  % -20V to +20V
LJ_rgBIP10V = 2;  % -10V to +10V
LJ_rgBIP5V = 3;   % -5V to +5V
LJ_rgBIP4V = 4;   % -4V to +4V
LJ_rgBIP2P5V = 5; % -2.5V to +2.5V
LJ_rgBIP2V = 6;   % -2V to +2V
LJ_rgBIP1P25V = 7;% -1.25V to +1.25V
LJ_rgBIP1V = 8;   % -1V to +1V
LJ_rgBIPP625V = 9;% -0.625V to +0.625V

LJ_rgUNI20V = 101;  % 0V to +20V
LJ_rgUNI10V = 102;  % 0V to +10V
LJ_rgUNI5V = 103;   % 0V to +5V
LJ_rgUNI4V = 104;   % 0V to +4V
LJ_rgUNI2P5V = 105; % 0V to +2.5V
LJ_rgUNI2V = 106;   % 0V to +2V
LJ_rgUNI1P25V = 107;% 0V to +1.25V
LJ_rgUNI1V = 108;   % 0V to +1V
LJ_rgUNIP625V = 109;% 0V to +0.625V
LJ_rgUNIP500V = 110; % 0V to +0.500V
LJ_rgUNIP3125V = 111; % 0V to +0.3125V

% timer modes (UE9 only):
LJ_tmPWM16 = 0; % 16 bit PWM
LJ_tmPWM8 = 1; % 8 bit PWM
LJ_tmRISINGEDGES32 = 2; % 32-bit rising to rising edge measurement
LJ_tmFALLINGEDGES32 = 3; % 32-bit falling to falling edge measurement
LJ_tmDUTYCYCLE = 4; % duty cycle measurement
LJ_tmFIRMCOUNTER = 5; % firmware based rising edge counter
LJ_tmFIRMCOUNTERDEBOUNCE = 6; % firmware counter with debounce
LJ_tmFREQOUT = 7; % frequency output
LJ_tmQUAD = 8; % Quadrature
LJ_tmTIMERSTOP = 9; % stops another timer after n pulses
LJ_tmSYSTIMERLOW = 10; % read lower 32-bits of system timer
LJ_tmSYSTIMERHIGH = 11; % read upper 32-bits of system timer
LJ_tmRISINGEDGES16 = 12; % 16-bit rising to rising edge measurement
LJ_tmFALLINGEDGES16 = 13; % 16-bit falling to falling edge measurement

% timer clocks:
LJ_tc750KHZ = 0;   % UE9: 750 khz 
LJ_tcSYS = 1;      % UE9: system clock

LJ_tc2MHZ = 10;     % U3
LJ_tc6MHZ = 11;     % U3
LJ_tc24MHZ = 12;     % U3
LJ_tc500KHZ_DIV = 13;% U3
LJ_tc2MHZ_DIV = 14;  % U3
LJ_tc6MHZ_DIV = 15;  % U3
LJ_tc24MHZ_DIV = 16; % U3

LJ_tc4MHZ = 20;     % U3
LJ_tc12MHZ = 21;     % U3
LJ_tc48MHZ = 22;     % U3
LJ_tc1MHZ_DIV = 23;% U3
LJ_tc4MHZ_DIV = 24;  % U3
LJ_tc12MHZ_DIV = 25;  % U3
LJ_tc48MHZ_DIV = 26; % U3

% stream wait modes
LJ_swNONE = 1;  % no wait, return whatever is available
LJ_swALL_OR_NONE = 2; % no wait, but if all points requested aren't available, return none.
LJ_swPUMP = 11;  % wait and pump the message pump.  Prefered when called from primary thread (if you don't know
                           % if you are in the primary thread of your app then you probably are.  Do not use in worker
                           % secondary threads (i.e. ones without a message pump).
LJ_swSLEEP = 12; % wait by sleeping (don't do this in the primary thread of your app, or it will temporarily 
                           % hang)  This is usually used in worker secondary threads.

% error codes:  These will always be in the range of -1000 to 3999 for labView compatibility (+6000)
LJE_NOERROR = 0;
 
LJE_INVALID_CHANNEL_NUMBER = 2; % occurs when a channel that doesn't exist is specified (i.e. DAC #2 on a UE9), or data from streaming is requested on a channel that isn't streaming
LJE_INVALID_RAW_INOUT_PARAMETER = 3;
LJE_UNABLE_TO_START_STREAM = 4;
LJE_UNABLE_TO_STOP_STREAM = 5;
LJE_NOTHING_TO_STREAM = 6;
LJE_UNABLE_TO_CONFIG_STREAM = 7;
LJE_BUFFER_OVERRUN = 8; % occurs when stream buffer overruns (this is the driver buffer not the hardware buffer).  Stream is stopped.
LJE_STREAM_NOT_RUNNING = 9;
LJE_INVALID_PARAMETER = 10;
LJE_INVALID_STREAM_FREQUENCY = 11; 
LJE_INVALID_AIN_RANGE = 12;
LJE_STREAM_CHECKSUM_ERROR = 13; % occurs when a stream packet fails checksum.  Stream is stopped
LJE_STREAM_COMMAND_ERROR = 14; % occurs when a stream packet has invalid command values.  Stream is stopped.
LJE_STREAM_ORDER_ERROR = 15; % occurs when a stream packet is received out of order (typically one is missing).  Stream is stopped.
LJE_AD_PIN_CONFIGURATION_ERROR = 16; % occurs when an analog or digital request was made on a pin that isn't configured for that type of request
LJE_REQUEST_NOT_PROCESSED = 17; % When a LJE_AD_PIN_CONFIGURATION_ERROR occurs, all other IO requests after the request that caused the error won't be processed. Those requests will return this error.
LJE_XBAR_CONFIG_ERROR = 18; % 

% U3 Specific Errors
LJE_SCRATCH_ERROR = 19;
LJE_DATA_BUFFER_OVERFLOW = 20;
LJE_ADC0_BUFFER_OVERFLOW = 21;
LJE_FUNCTION_INVALID = 22;
LJE_SWDT_TIME_INVALID = 23;
LJE_FLASH_ERROR = 24;
LJE_STREAM_IS_ACTIVE = 25;
LJE_STREAM_TABLE_INVALID = 26;
LJE_STREAM_CONFIG_INVALID = 27;
LJE_STREAM_BAD_TRIGGER_SOURCE = 28;
LJE_STREAM_INVALID_TRIGGER = 30;
LJE_STREAM_ADC0_BUFFER_OVERFLOW = 31;
LJE_STREAM_SCAN_OVERLAP = 32;
LJE_STREAM_SAMPLE_NUM_INVALID = 33;
LJE_STREAM_BIPOLAR_GAIN_INVALID = 34;
LJE_STREAM_SCAN_RATE_INVALID = 35;
LJE_TIMER_INVALID_MODE = 36;
LJE_TIMER_QUADRATURE_AB_ERROR = 37;
LJE_TIMER_QUAD_PULSE_SEQUENCE = 38;
LJE_TIMER_BAD_CLOCK_SOURCE = 39;
LJE_TIMER_STREAM_ACTIVE = 40;
LJE_TIMER_PWMSTOP_MODULE_ERROR = 41;
LJE_TIMER_SEQUENCE_ERROR = 42;
LJE_TIMER_SHARING_ERROR = 43;
LJE_TIMER_LINE_SEQUENCE_ERROR = 44;
LJE_EXT_OSC_NOT_STABLE = 45;
LJE_INVALID_POWER_SETTING = 46;
LJE_PLL_NOT_LOCKED = 47;
LJE_INVALID_PIN = 48;
LJE_IOTYPE_SYNCH_ERROR = 49;
LJE_INVALID_OFFSET = 50;
LJE_FEEDBACK_IOTYPE_NOT_VALID = 51;



LJE_MIN_GROUP_ERROR = 1000; % all errors above this number will stop all requests, below this number are request level errors.

LJE_UNKNOWN_ERROR = 1001; % occurs when an unknown error occurs that is caught, but still unknown.
LJE_INVALID_DEVICE_TYPE = 1002; % occurs when devicetype is not a valid device type
LJE_INVALID_HANDLE = 1003; % occurs when invalid handle used
LJE_DEVICE_NOT_OPEN = 1004;  % occurs when Open() fails and AppendRead called despite.
LJE_NO_DATA_AVAILABLE = 1005; % this is cause when GetData() called without calling DoRead(), or when GetData() passed channel that wasn't read
LJE_NO_MORE_DATA_AVAILABLE = 1006;
LJE_LABJACK_NOT_FOUND = 1007; % occurs when the labjack is not found at the given id or address.
LJE_COMM_FAILURE = 1008; % occurs when unable to send or receive the correct # of bytes
LJE_CHECKSUM_ERROR = 1009;
LJE_DEVICE_ALREADY_OPEN = 1010; 
LJE_COMM_TIMEOUT = 1011;
LJE_USB_DRIVER_NOT_FOUND = 1012;
LJE_INVALID_CONNECTION_TYPE = 1013;
LJE_INVALID_MODE = 1014;

% warning are negative
LJE_DEVICE_NOT_CALIBRATED = -1; % defaults used instead
LJE_UNABLE_TO_READ_CALDATA = -2; % defaults used instead



% depreciated constants:
LJ_ioANALOG_INPUT = 10;  
LJ_ioANALOG_OUTPUT = 20; % UE9 + U3
LJ_ioDIGITAL_BIT_IN = 30; % UE9 + U3
LJ_ioDIGITAL_PORT_IN = 35; % UE9 + U3 
LJ_ioDIGITAL_BIT_OUT = 40; % UE9 + U3
LJ_ioDIGITAL_PORT_OUT = 45; % UE9 + U3
LJ_ioCOUNTER = 50; % UE9 + U3
LJ_ioTIMER = 60; % UE9 + U3
LJ_ioPUT_COUNTER_MODE = 2010; % UE9
LJ_ioGET_COUNTER_MODE = 2011; % UE9
LJ_ioGET_TIMER_VALUE = 2007; % UE9
LJ_ioCYCLE_PORT = 102;  % UE9 
LJ_chTIMER_CLOCK_CONFIG = 1001; % UE9 + U3 % depr
