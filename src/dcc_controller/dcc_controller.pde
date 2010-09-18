/*
* DCC Controller
* 
*  Takes commands from the train controller GUI and
* converts them to DCC commands. The logic levels from
* the Arduino will be used by the driver stage to supply
* the rails.
*
*  Timing of the output waveforms is very important for the 
* DCC specification, so an interrupt on the timer schedules 
* the updates of the output pins. 
* 
*  
*/

#define FORWARD 0.bit(0)
#define BACKWARD 1.bit(0)

#define CMD_STOP 'S'
#define CMD_FORWARD 'F'
#define CMD_BACKWARD 'B'
#define CMD_SPEED 'V'
#define CMD_ADDR 'A'
#define CMD_GO 'F'

#define DCC_IDLE 0
#define DCC_BASE 1

int enable_pin = 13;
int drive_a_pin = 14;
int drive_b_pin = 15;

char cmd;
char dev_addr = 3;
char dev_speed = 3;

void setup() {
  pinMode(enable_pin, OUTPUT);
  pinMode(drive_a_pin, OUTPUT);
  pinMode(drive_b_pin, OUTPUT);
  
  digitalWrite(enable_pin, LOW);

  Serial.begin(9600);
}


void loop() {
  
  if(Serial.available() > 0 ) {
    cmd = Serial.read(); 
   
    switch(cmd) {
   
      case CMD_STOP:
        dcc_packet(DCC_BASE, dev_addr, 0 );
        break;
        
      case CMD_GO:
        dcc_packet(DCC_BASE, dev_addr, dev_speed);
        break;
        
      case CMD_SPEED:
        dev_speed = int(Serial.read()) - 49;
        dcc_packet(DCC_BASE, dev_addr, dev_speed);
        break;
        
      case CMD_ADDR:
        dev_addr = int(Serial.read()) -49;
        dcc_packet(DCC_BASE, dev_addr, dev_speed);
        break;
      
      default:
        dcc_packet(DCC_IDLE,0,0);
    }
    
  } else {
    dcc_packet(DCC_IDLE,0,0);
  }
  
}


void dcc_packet(int packet_type, int dev_addr, int dev_speed) {
  
  byte 
#ifdef DEBUG
  Serial.print(packet_type);
  Serial.print(dev_addr);
  Serial.print(dev_speed);
  Serial.println();
#endif
  digitalWrite(enable_pin, HIGH);
  
  
  
}

