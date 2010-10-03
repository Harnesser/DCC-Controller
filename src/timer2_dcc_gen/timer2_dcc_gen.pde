//
// Generating a DCC Signal using Timer2 and the Waveform Generator
//

#include <avr/io.h>
#include <avr/interrupt.h> 

#define LED_PIN 5  // digital pin #13 (portb)
#define LED_ON() PORTB |= _BV(LED_PIN)
#define LED_OFF() PORTB &= ~_BV(LED_PIN)

#define PIN_14 4
#define LED1_ON() PORTB |= _BV(PIN_14)
#define LED1_OFF() PORTB &= ~_BV(PIN_14)

#define TRIG 3
#define TRIG_ON() PORTB |= _BV(TRIG)
#define TRIG_OFF() PORTB &= ~_BV(TRIG)

#define PATTERN_BYTES 18

byte timer2_target = 100;
unsigned int mycount = 0;

byte dcc_bit_pattern[PATTERN_BYTES];
byte dcc_bit_pattern_buffered[PATTERN_BYTES];

byte c_bit;
byte dcc_bit_count_target;
byte dcc_bit_count_target_buffered;

byte c_buf;

boolean valid_frame = false;

void setup() {
  
  // Setup Timer2 
  configure_for_dcc_timing();
  
  pinMode(13,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(12,OUTPUT);
  pinMode(11,OUTPUT);
  digitalWrite(9,LOW);
  digitalWrite(11,LOW);
  
  // Messing
  Serial.begin(9600);
  show_bit_pattern();
  
  build_frame(3,true,2);
  show_bit_pattern();
  
  build_frame(5,false,2);
  show_bit_pattern();

  load_new_frame();
  c_buf = 0;  
  
  Serial.print("Count target:");
  Serial.println(dcc_bit_count_target, DEC);
  
  sei();  // Enable interrupts
}


ISR( TIMER2_COMPA_vect ){
  TCNT2 = 0; // Reset Timer2 counter to divide...

  boolean bit_ = bitRead(dcc_bit_pattern_buffered[c_buf>>3], c_buf & 7 );

  if( bit_ ) {
    LED_OFF();
    LED1_ON();
  } else {
    LED_ON();
    LED1_OFF();
  }  
  
  /* Trigger for start of packet */
/*  if(c_buf == (dcc_bit_count_target_buffered >> 1) ){
    TRIG_OFF();
  } else if( c_buf == dcc_bit_count_target_buffered ) {
    TRIG_ON();  
  }
*/

  if(c_buf == 0 ){
    TRIG_ON();
  } else {
    TRIG_OFF();
  }
  
  /* Now update our position */
  if(c_buf == dcc_bit_count_target_buffered){
    c_buf = 0;
    load_new_frame();
  } else {
    c_buf++;
  }
   
  //Serial.println(c_buf, DEC);
  
};

void configure_for_dcc_timing() {

  /* DCC timing requires that the data toggles every 58us
  for a '1'. So, we set up timer2 to fire an interrupt every
  58us, and we'll change the output in the interrupt service 
  routine.
 
  Prescaler: set to divide-by-8 (B'010)
  Compare target: 58us / ( 1 / ( 16MHz/8) ) = 116
  */
  
  byte timer2_target = 114; // remember off-by-one -> count starts at 0

  // Set prescaler to div-by-8
  bitClear(TCCR2B, CS22);
  bitSet(TCCR2B, CS21);
  bitClear(TCCR2B, CS20);
  
  // Set counter target
  OCR2A = timer2_target;
    
  // Enable Timer2 interrupt
  bitSet(TIMSK2, OCIE2A); 
}


void loop(){

}

/* --------------------------------------------------------------
 *  DCC Packet setup
 * --------------------------------------------------------------
 */

void bit_pattern(byte mybit){

    bitClear(dcc_bit_pattern[c_bit>>3], c_bit & 7 );
    c_bit++;
    
    if( mybit == 0 ) {
       bitClear(dcc_bit_pattern[c_bit>>3], c_bit & 7 );
       c_bit++;   
    }
    
    bitSet(dcc_bit_pattern[c_bit>>3], c_bit & 7 );
    c_bit++;
    
    if( mybit == 0 ) {
       bitSet(dcc_bit_pattern[c_bit>>3], c_bit & 7 );
       c_bit++;   
    }
    
}

/* DCC pattern for this byte: MSB first */
void byte_pattern( byte mybyte ) {
  for( int i=7; i>=0; i-- ) {
    bit_pattern( byte( bitRead( mybyte, i ) ) );
  } 
};


/* Preamble pattern, 14 '1's */
void preamble_pattern() {
  for( byte i=0; i < 14; i++ ){
    bit_pattern(1);
  } 
}


/* Command Pattern */
byte calc_command_pattern( boolean dcc_forward, byte dcc_speed ) {
  byte command_byte;
  command_byte = B01000000 | ( dcc_forward << 5 ) | ( dcc_speed & B00011111 );
  return command_byte;
};


void show_dcc_bytes( byte command_byte, byte dcc_address, byte addr_cmd_xor ) {   
  Serial.print("Command byte         :");
  Serial.println(command_byte, BIN);
  Serial.print("Address byte         :");
  Serial.println(dcc_address, BIN);
  Serial.print("Error Correction Byte:");
  Serial.println(addr_cmd_xor, BIN);
};


/* Build the DCC frame */
void build_frame(byte dcc_address, boolean dcc_forward, byte dcc_speed) {

  valid_frame = false;
  byte dcc_command = calc_command_pattern( dcc_forward, dcc_speed );
  byte dcc_checksum = dcc_command ^ dcc_address;
  show_dcc_bytes(dcc_command, dcc_address, dcc_checksum );
  
  // Build up the bit pattern for the DCC frame 
  _build_frame(dcc_address, dcc_command, dcc_checksum);
 
  valid_frame = true;
};

void build_idle_frame(){
  valid_frame = false;
  _build_frame(B11111111, B00000000, B11111111);
  valid_frame = true;
};

void build_reset_frame(){
  valid_frame = false;
  _build_frame(B00000000, B00000000, B00000000);
  valid_frame = true;
};

void _build_frame( byte byte1, byte byte2, byte byte3) {
   
  // Build up the bit pattern for the DCC frame 
  c_bit = 0;
  preamble_pattern();

  bit_pattern(LOW);
  byte_pattern(byte1);

  bit_pattern(LOW);
  byte_pattern(byte2);

  bit_pattern(LOW);
  byte_pattern(byte3);

  bit_pattern(HIGH);  
  
  dcc_bit_count_target = c_bit;
  
};


void load_new_frame(){
  if( valid_frame ) {
    Serial.println("Loading a new frame");
    for(int i=0; i<PATTERN_BYTES; i++){
      dcc_bit_pattern_buffered[i] = dcc_bit_pattern[i];
    }
    dcc_bit_count_target_buffered = dcc_bit_count_target-1;
    valid_frame = false;
  }
};


void show_bit_pattern(){
  for( int i=0; i<PATTERN_BYTES; i++){ 
    Serial.println(dcc_bit_pattern[i], BIN); 
  }
}
