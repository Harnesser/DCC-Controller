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

byte timer2_target = 100;
unsigned int mycount = 0;

byte dcc_bit_pattern[18];
byte c_bit;

byte dcc_address;
byte dcc_command;
byte dcc_check;


void setup() {
  
  // Setup Timer2 
  configure_for_dcc_timing();
  
  pinMode(13,OUTPUT);
  pinMode(9,OUTPUT);
  pinMode(12,OUTPUT);
  digitalWrite(9,LOW);

  sei();  // Enable interrupts
  
  // Messing
  dcc_address = 3;
  dcc_check = 5;
  
  Serial.begin(9600);
  show_bit_pattern();
  build_frame();
  show_bit_pattern();
  
  dcc_address = 5;
  build_frame();
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


/* Preamble pattern, 14 '1's */
void preamble_pattern() {
  for( byte i=0; i < 14; i++ ){
    bit_pattern(1);
  } 
}

/* Address Pattern, MSB first */
void address_pattern() {
  for( int i=7; i>=0; i-- ) {
    bit_pattern( byte( bitRead( dcc_address, i ) ) );
  }
}

/* Build the DCC frame */
void build_frame() {
  c_bit = 0;
  preamble_pattern();
  bit_pattern(LOW);
  address_pattern();
  bit_pattern(LOW);
}


void show_bit_pattern(){
  for( int i=0; i<18; i++){ 
    Serial.println(dcc_bit_pattern[i], BIN); 
  }
}
