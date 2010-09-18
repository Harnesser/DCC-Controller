//
// Generating a DCC Signal using Timer2 and the Waveform Generator
//

#include <avr/io.h>
#include <avr/interrupt.h> 

#define LED_PIN 5  // digital pin #13 (portb)
#define LED_ON() PORTB |= _BV(LED_PIN)
#define LED_OFF() PORTB &= ~_BV(LED_PIN)

byte timer2_target = 128;
unsigned int mycount = 0;

void setup() {
  
  // Enable Timer2 
  OCR2A = timer2_target;
  bitSet(TCCR2B, CS22);
  bitSet(TCCR2B, CS21);
  bitSet(TCCR2B, CS20);
  
  pinMode(13,OUTPUT);
  
  // Enable Timer2 interrupt
  bitSet(TIMSK2, OCIE2A); 
  sei();  
}

ISR( TIMER2_COMPA_vect ){
  mycount += 1;

  if( mycount == 128 ) {
    LED_OFF();
  } else if (mycount == 255 ) {
    LED_ON();
    mycount = 0;
  }  
  
};


void loop(){
}


