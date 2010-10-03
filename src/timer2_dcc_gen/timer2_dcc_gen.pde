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

#define PATTERN_BYTES 18

byte timer2_target = 100;
unsigned int mycount = 0;

byte dcc_bit_pattern[PATTERN_BYTES];
byte c_bit;
byte dcc_bit_count_target;

void setup() {
  
  // Setup Timer2 
  configure_for_dcc_timing();
  
  pinMode(13,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(12,OUTPUT);
  digitalWrite(9,LOW);

  sei();  // Enable interrupts
  
  // Messing
  Serial.begin(9600);
  show_bit_pattern();
  
  build_frame(3,true,2);
  show_bit_pattern();
  
  build_frame(5,false,2);
  show_bit_pattern();
  
}


ISR( TIMER2_COMPA_vect ){
  mycount += 1;

  if( (mycount & 1 ) == HIGH ) {
    LED_OFF();
    LED1_ON();
  } else {
    LED_ON();
    LED1_OFF();
  }  
  
  TCNT2 = 0; // Reset Timer2 counter to divide...
  
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

  byte dcc_command = calc_command_pattern( dcc_forward, dcc_speed );
  byte dcc_checksum = dcc_command ^ dcc_address;
  show_dcc_bytes(dcc_command, dcc_address, dcc_checksum );
  
  // Build up the bit pattern for the DCC frame 
  c_bit = 0;
  preamble_pattern();

  bit_pattern(LOW);
  byte_pattern(dcc_address);

  bit_pattern(LOW);
  byte_pattern(dcc_command);

  bit_pattern(LOW);
  byte_pattern(dcc_checksum);

  bit_pattern(HIGH);  
  
  dcc_bit_count_target = c_bit;
};


void _build_frame( byte addr, byte cmd ) {
  
    
  
  
};


void show_bit_pattern(){
  for( int i=0; i<PATTERN_BYTES; i++){ 
    Serial.println(dcc_bit_pattern[i], BIN); 
  }
}
